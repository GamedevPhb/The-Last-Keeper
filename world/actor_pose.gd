extends Node
## Procedural pose for a rigged character. The Mixamo FBX files ship a single-frame clip (a
## T-pose) and there is no animation pack, so this drives the Skeleton3D itself: arms come down
## from the T-pose, the chest breathes, the head sways, and a mode adds the rest:
## IDLE (stand), TALK (nod and a hand gesture), WALK (legs and arms swing), ROW (oar stroke).
## Works with the Mixamo rig (mixamorig_*) and with `assets/personagem/keeper.glb` (upper_arm.L...).
## Every target is a direction in the character's own space (+Z forward, +X its left), turned
## into a rotation from the bone's current direction, so the rig's odd rest axes do not matter.

enum Mode { IDLE, TALK, WALK, ROW }

## key -> candidate bone names (Mixamo, then keeper.glb).
const NAMES := {
	"hips": ["mixamorig_Hips", "mixamorig:Hips", "hips"],
	"spine": ["mixamorig_Spine", "mixamorig:Spine", "spine"],
	"chest": ["mixamorig_Spine2", "mixamorig:Spine2", "chest"],
	"neck": ["mixamorig_Neck", "mixamorig:Neck", "neck"],
	"head": ["mixamorig_Head", "mixamorig:Head", "head"],
	"l_arm": ["mixamorig_LeftArm", "mixamorig:LeftArm", "upper_arm.L"],
	"l_fore": ["mixamorig_LeftForeArm", "mixamorig:LeftForeArm", "forearm.L"],
	"l_hand": ["mixamorig_LeftHand", "mixamorig:LeftHand", "hand.L"],
	"r_arm": ["mixamorig_RightArm", "mixamorig:RightArm", "upper_arm.R"],
	"r_fore": ["mixamorig_RightForeArm", "mixamorig:RightForeArm", "forearm.R"],
	"r_hand": ["mixamorig_RightHand", "mixamorig:RightHand", "hand.R"],
	"l_up": ["mixamorig_LeftUpLeg", "mixamorig:LeftUpLeg", "thigh.L"],
	"l_leg": ["mixamorig_LeftLeg", "mixamorig:LeftLeg", "shin.L"],
	"l_foot": ["mixamorig_LeftFoot", "mixamorig:LeftFoot", "foot.L"],
	"r_up": ["mixamorig_RightUpLeg", "mixamorig:RightUpLeg", "thigh.R"],
	"r_leg": ["mixamorig_RightLeg", "mixamorig:RightLeg", "shin.R"],
	"r_foot": ["mixamorig_RightFoot", "mixamorig:RightFoot", "foot.R"],
}
const WALK_RATE := 5.0 ## rad/s of the gait
const ROW_RATE := 2.4 ## rad/s of the oar stroke

var mode := Mode.IDLE
## Set by whoever plays the voice: nods the head and moves a hand (any mode but ROW).
var talking := false

var _skeleton: Skeleton3D
var _frame: Node3D ## the character root: +Z forward, +X left
var _bones := {}
var _rest := {}
var _t := 0.0


## Adds a pose driver to `character` (the Node3D that holds the model). Null without a skeleton.
static func attach(character: Node3D, skeleton_owner: Node = null) -> Node:
	var skeleton: Skeleton3D = null
	for found in (skeleton_owner if skeleton_owner else character).find_children("*", "Skeleton3D", true, false):
		skeleton = found
		break
	if skeleton == null:
		return null
	var pose: Node = load("res://world/actor_pose.gd").new()
	pose.name = "ActorPose"
	pose._skeleton = skeleton
	pose._frame = character
	character.add_child(pose)
	return pose


func _ready() -> void:
	_t = randf() * 20.0
	for key: String in NAMES:
		for candidate: String in NAMES[key]:
			var index := _skeleton.find_bone(candidate)
			if index >= 0:
				_bones[key] = index
				_rest[key] = _skeleton.get_bone_rest(index)
				break
	# The imported clip is one frame of T-pose; it must not fight the procedural pose.
	for found in _frame.find_children("*", "AnimationPlayer", true, false):
		(found as AnimationPlayer).stop()
		(found as AnimationPlayer).process_mode = Node.PROCESS_MODE_DISABLED
	if is_inside_tree():
		pose_now()


func _process(delta: float) -> void:
	_t += delta
	pose_now()


## Angle in degrees between the arm (shoulder to elbow) and the torso's downward line (neck to
## hips): about 90 in a T-pose, 10-30 with the arm down, up to ~60 rowing.
func arm_angle(left := true) -> float:
	var arm: int = _bones.get("l_arm" if left else "r_arm", -1)
	var fore: int = _bones.get("l_fore" if left else "r_fore", -1)
	if arm < 0 or fore < 0 or not _bones.has("hips") or not _bones.has("neck"):
		return -1.0
	var limb := _origin(fore) - _origin(arm)
	var torso := _origin(_bones.hips) - _origin(_bones.neck)
	return rad_to_deg(limb.angle_to(torso))


func has_rig() -> bool:
	return _bones.has("l_arm") and _bones.has("r_arm")


## Applies this frame's pose (also called once on attach, so the first frame is never a T-pose).
func pose_now() -> void:
	if _skeleton == null or not _skeleton.is_inside_tree() or not has_rig():
		return
	for key: String in _bones:
		_skeleton.set_bone_pose_rotation(_bones[key], (_rest[key] as Transform3D).basis.get_rotation_quaternion())
	var breath := sin(_t * 1.7)
	var walking := mode == Mode.WALK
	var rowing := mode == Mode.ROW
	var phase := _t * (WALK_RATE if walking else ROW_RATE)
	# Trunk and head.
	_turn("spine", Vector3.RIGHT, breath * 0.015 + (sin(phase) * 0.04 if rowing else 0.0))
	_turn("chest", Vector3.RIGHT, breath * 0.02 + (0.1 + sin(phase) * 0.12 if rowing else 0.0))
	_turn("chest", Vector3.FORWARD, sin(_t * 0.6) * 0.015 + (sin(phase) * 0.05 if walking else 0.0))
	_turn("head", Vector3.UP, sin(_t * 0.45) * 0.1)
	if talking and not rowing:
		_turn("head", Vector3.RIGHT, absf(sin(_t * 6.0)) * 0.09 - 0.02)
		_turn("head", Vector3.UP, sin(_t * 2.3) * 0.1)
	# Arms: down from the T-pose, forearm slightly bent; modes override the targets.
	for side in [1.0, -1.0]:
		var left: bool = side > 0.0
		var p := "l_" if left else "r_"
		var swing := sin(phase + (0.0 if left else PI))
		var upper := Vector3(side * 0.18, -1.0, 0.1)
		var lower := Vector3(side * 0.1, -0.85, 0.45)
		if walking:
			upper = Vector3(side * 0.15, -1.0, swing * 0.5)
			lower = Vector3(side * 0.1, -0.8, 0.3 + swing * 0.3)
		elif rowing:
			upper = Vector3(side * 0.28, -0.55 + 0.25 * cos(phase), 0.6 + 0.35 * sin(phase))
			lower = Vector3(side * 0.12, -0.3 + 0.2 * cos(phase), 0.9)
		elif talking and not left:
			var beat := sin(_t * 3.1)
			upper = Vector3(side * 0.35, -0.8, 0.25)
			lower = Vector3(-side * 0.2 + beat * 0.15, 0.1 + beat * 0.25, 0.9)
		_aim(p + "arm", p + "fore", upper)
		_aim(p + "fore", p + "hand", lower)
	# Legs: only when walking.
	if walking and _bones.has("l_up") and _bones.has("r_up"):
		for side in [1.0, -1.0]:
			var p := "l_" if side > 0.0 else "r_"
			var step := sin(phase + (0.0 if side > 0.0 else PI))
			_aim(p + "up", p + "leg", Vector3(0.0, -1.0, step * 0.55))
			_aim(p + "leg", p + "foot", Vector3(0.0, -1.0, -maxf(-step, 0.0) * 0.7))
		if _bones.has("hips"):
			var rest_pos: Vector3 = (_rest.hips as Transform3D).origin
			_skeleton.set_bone_pose_position(_bones.hips, rest_pos * Vector3(1.0, 1.0 - 0.012 * absf(sin(phase)), 1.0))


## Direction `v` in the character's frame as a unit vector in skeleton space.
func _dir(v: Vector3) -> Vector3:
	var world := _frame.global_transform.basis * v
	return (_skeleton.global_transform.basis.inverse() * world).normalized()


func _origin(index: int) -> Vector3:
	return _skeleton.get_bone_global_pose(index).origin


## Spins a bone by `angle` radians around `axis` (character frame), on top of its current pose.
func _turn(key: String, axis: Vector3, angle: float) -> void:
	if not _bones.has(key):
		return
	_rotate(_bones[key], Quaternion(_dir(axis), angle))


## Points bone `key` (toward its child `child_key`) along `target`, a direction in the character frame.
func _aim(key: String, child_key: String, target: Vector3) -> void:
	if not _bones.has(key) or not _bones.has(child_key):
		return
	var index: int = _bones[key]
	var current := (_origin(_bones[child_key]) - _origin(index)).normalized()
	_rotate(index, Quaternion(current, _dir(target)))


## Applies `q` (skeleton space) to the bone's global orientation, keeping its parents as they are.
func _rotate(index: int, q: Quaternion) -> void:
	var parent := _skeleton.get_bone_parent(index)
	var parent_q := Quaternion.IDENTITY
	if parent >= 0:
		parent_q = _skeleton.get_bone_global_pose(parent).basis.orthonormalized().get_rotation_quaternion()
	var local := _skeleton.get_bone_pose_rotation(index)
	_skeleton.set_bone_pose_rotation(index, parent_q.inverse() * q * parent_q * local)
