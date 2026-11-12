extends SceneTree
## Headless test: no character stays in a T-pose. The arms (shoulder to elbow) must hang well
## below horizontal, measured from the torso's downward line in every mode (idle, talk, walk, row).
## Run: godot-4 --headless --path . --script res://tests/pose_test.gd

const MAX_ARM := 60.0 ## a T-pose reads about 90
const MAX_ARM_ROW := 80.0 ## rowing reaches forward degrees
const KINDS := ["Character_13", "Character_19_Female_Police", "Character_Killer_01", "keeper"]

var _failures := 0
var _frames := 0
var _cast: Array = []


func _initialize() -> void:
	var x := 0.0
	for kind: String in KINDS:
		var actor: Node3D = Actors.keeper() if kind == "keeper" else Actors.character(kind)
		actor.position.x = x
		x += 2.0
		root.add_child(actor)
		_cast.append(actor)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 4:
		return false
	var modes := ["IDLE", "TALK", "WALK", "ROW"]
	for actor: Node3D in _cast:
		var pose: Node = Actors.pose_of(actor)
		_check(pose != null and pose.has_rig(), "%s has a pose driver" % actor.name)
		if pose == null:
			continue
		for mode_name: String in modes:
			pose.mode = pose.Mode.get(mode_name if mode_name != "TALK" else "IDLE")
			pose.talking = mode_name == "TALK"
			pose.pose_now()
			for left in [true, false]:
				var angle: float = pose.arm_angle(left)
				_check(angle >= 0.0 and angle < (MAX_ARM_ROW if mode_name == "ROW" else MAX_ARM), "%s %s %s arm at %.0f deg (T-pose is ~90)" % [actor.name, mode_name, "left" if left else "right", angle])
	if _failures > 0:
		printerr("POSE TEST FAILED: %d checks" % _failures)
		quit(1)
	else:
		print("POSE TEST PASSED")
		quit(0)
	return true


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)
