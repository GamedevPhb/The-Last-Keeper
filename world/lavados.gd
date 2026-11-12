extends Node3D
## The Lavados (HISTORIA 4 #01): bluish drowned men that come ashore from 00:00, back to the
## island. A statue while the lamp's beam sweeps over them; when it looks away they take steps
## toward the tower, faster once the clockwork stops. Touching one with the cord at 0 costs 35
## health, then 3 s of grace. They can be killed (`lavado_body.gd`: 60 hp, group "enemies") and
## come toward loud noises (shots, axe hits) for a few seconds.

const MODELS := ["Character_Killer_01", "Character_Killer_02", "Character_Killer_03",
	"Character_Killer_04", "Character_Killer_05"]
const SPOTS := [Vector3(-14.0, 0.0, 33.0), Vector3(10.0, 0.0, 30.0), Vector3(-5.0, 0.0, 37.0),
	Vector3(18.0, 0.0, 25.0), Vector3(-22.0, 0.0, 28.0)]
const FROM := 24.0 * 60.0
const TARGET := Vector3(0.0, 0.0, -8.0)
const WALK := 0.9 ## m/s with the cord winding
const LOOSE_WALK := 1.7 ## m/s with the cord stopped
const TOUCH := 1.1
const TOUCH_DAMAGE := 35.0
const GRACE := 3.0
const BODY := preload("res://world/lavado_body.gd")
const INVADER_WALK := 1.9 ## m/s of an invasion Lavado (base)
const ALERT_TIME := 8.0
const ALERT_SPEED := 1.25 ## walking speed multiplier while drawn by a noise

var _walkers: Array[Node3D] = []
var _grace := 0.0
var _spawned := 0 ## how many have come ashore, dead or alive (the dead do not come back)


## How many are ashore: 3 at midnight, one more at 02:00 and at 04:00.
func wanted() -> int:
	var minutes: float = GameState.minutes
	if minutes < FROM:
		return 0
	return 3 + int(minutes >= FROM + 120.0) + int(minutes >= FROM + 240.0)


func _ready() -> void:
	GameState.noise_made.connect(_on_noise)


func walkers() -> Array[Node3D]:
	return _walkers


func _physics_process(delta: float) -> void:
	if not GameState.in_game or GameState.dead or GameState.scene_active:
		return
	while _spawned < mini(wanted(), MODELS.size()):
		_spawn(_spawned)
		_spawned += 1
	_grace = maxf(_grace - delta, 0.0)
	var beacon := get_tree().get_first_node_in_group("beacon")
	var loose: bool = beacon == null or not beacon.is_sweeping()
	for walker in _walkers.duplicate():
		var body: Node3D = walker
		var pushed: Vector3 = body.consume_knock(delta)
		if pushed != Vector3.ZERO:
			walker.global_position = _ground(walker.global_position + pushed)
		var pose := Actors.pose_of(walker)
		if body.stun > 0.0:
			if pose:
				pose.mode = pose.Mode.IDLE
			continue
		if beacon and beacon.beam_covers(walker.global_position):
			if pose:
				pose.mode = pose.Mode.IDLE
			continue
		if pose:
			pose.mode = pose.Mode.WALK
		var speed := (LOOSE_WALK if loose else WALK) * (ALERT_SPEED if body.alert > 0.0 else 1.0)
		if body.invader:
			speed = INVADER_WALK * (ALERT_SPEED if body.alert > 0.0 else 1.0)
		_step(walker, speed * body.speed_scale * delta)
		_touch(walker, loose or body.invader)


func _spawn(i: int) -> void:
	spawn_foe(MODELS[i], SPOTS[i])


## Puts one Lavado ashore (also used by the invasion, `invasion.gd`). `invader` ones hunt the
## keeper instead of marching on the tower and also hit while the cord winds (the beam still
## freezes them); `hp` / `speed` scale the base body. Returns the body.
func spawn_foe(model: String, at: Vector3, invader := false, hp := 1.0, speed := 1.0, tint := Color(0.55, 0.7, 0.95)) -> Node3D:
	var walker := Actors.character(model, tint, 0.7)
	walker.set_script(BODY)
	walker.health = BODY.MAX_HEALTH * hp
	walker.speed_scale = speed
	walker.invader = invader
	walker.died.connect(func(dead: Node3D) -> void: _walkers.erase(dead))
	add_child(walker)
	walker.global_position = _ground(at)
	_walkers.append(walker)
	GameState.enemy_emerged(walker.global_position)
	return walker


func _step(walker: Node3D, distance: float) -> void:
	var pos := walker.global_position
	var goal := TARGET
	var stop := 3.0
	if walker.invader:
		stop = 0.6
		if GameState.player:
			goal = GameState.player.global_position
	if walker.alert > 0.0:
		goal = walker.alert_at
	var flat := Vector3(goal.x - pos.x, 0.0, goal.z - pos.z)
	if flat.length() < stop:
		return
	var dir := flat.normalized()
	walker.rotation.y = lerp_angle(walker.rotation.y, atan2(dir.x, dir.z), 0.2)
	walker.global_position = _ground(pos + dir * distance)


func _touch(walker: Node3D, loose: bool) -> void:
	var player := GameState.player
	if not loose or _grace > 0.0 or player == null:
		return
	if walker.global_position.distance_to(player.global_position) < TOUCH:
		_grace = GRACE
		GameState.damage(TOUCH_DAMAGE, "Um afogado")


## A shot or a blow carries: every Lavado inside `radius` turns toward it for a while.
func _on_noise(at: Vector3, radius: float) -> void:
	for walker in _walkers:
		var reach: float = radius * (1.5 if walker.invader else 1.0) # the tide's dead listen harder
		if walker.global_position.distance_to(at) <= reach:
			walker.alert = ALERT_TIME * (1.5 if walker.invader else 1.0)
			walker.alert_at = at


## Drops a point onto the world (layer 1), staying put if there is only water below.
func _ground(point: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(Vector3(point.x, 30.0, point.z), Vector3(point.x, -5.0, point.z), 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return Vector3(point.x, maxf(point.y, 0.0), point.z)
	return hit.position
