extends Node3D
## "O barqueiro não desembarcou": the boatman waits in his small boat by the pier at the start of
## the night (the opening cutscene drives him from there to the ship at the horizon), and comes
## back to the same spot as dawn nears (from 05:00, moored by 06:00).

const SMALL_BOAT := preload("res://world/small_boat.tscn")
const HORIZON := preload("res://world/horizon_ship.gd")
const SEA := -1.2
const MOOR := Vector3(3.3, SEA, 47.5)
const START_WINDOW := 1.5 ## game minutes after 17:30 he is still at the pier, unless he left
const RETURN_FROM := 29.0 * 60.0
const RETURN_TO := 29.9 * 60.0

var gone := false ## left for the ship (set by the cutscene)
var _boat: Node3D
var _man: Node3D
var _time := 0.0
var _bob := true
var _pose: Node ## actor_pose.gd of the man in the boat


func _ready() -> void:
	add_to_group("boatman")
	_boat = SMALL_BOAT.instantiate() as Node3D
	add_child(_boat)
	_man = Actors.character("Character_13")
	_man.position = (_boat.get_node("Seat") as Node3D).position
	_man.rotation.y = -PI / 2.0
	_boat.add_child(_man)
	_pose = Actors.pose_of(_man)
	position = MOOR
	_update()


func _process(delta: float) -> void:
	_time += delta
	_update()


## Moves the boat to `point`, heading the way it goes (the cutscene's sailing). Stops bobbing in place.
func sail_to(point: Vector3) -> void:
	_bob = false
	if _pose:
		_pose.mode = _pose.Mode.ROW
	var step := Vector2(point.x - position.x, point.z - position.z)
	if step.length() > 0.001:
		rotation.y = lerp_angle(rotation.y, atan2(-step.x, -step.y), 0.1)
		_man.rotation.y = lerp_angle(_man.rotation.y, PI, 0.1)
	position = Vector3(point.x, SEA + sin(_time * 1.3) * 0.05, point.z)


## The cutscene sets this while his line plays (nods and gestures).
func set_talking(on: bool) -> void:
	if _pose:
		_pose.talking = on


## He steps behind the hull of the ship and is gone for the night.
func board() -> void:
	gone = true
	_bob = true
	if _pose:
		_pose.mode = _pose.Mode.IDLE
	visible = false


func _update() -> void:
	var minutes: float = GameState.minutes
	if gone and minutes < RETURN_FROM:
		visible = false
		return
	if not _bob:
		return
	visible = minutes < GameState.START_MINUTES + START_WINDOW or minutes >= RETURN_FROM
	if minutes >= RETURN_FROM:
		var arrive := smoothstep(RETURN_FROM, RETURN_TO, minutes)
		var from: Vector3 = HORIZON.SIDE
		var spot := from.lerp(MOOR, arrive)
		var step := Vector2(spot.x - position.x, spot.z - position.z)
		if arrive < 1.0 and step.length() > 0.001:
			rotation.y = lerp_angle(rotation.y, atan2(-step.x, -step.y), 0.1)
			_man.rotation.y = lerp_angle(_man.rotation.y, PI, 0.1)
		else:
			rotation.y = lerp_angle(rotation.y, 0.0, 0.1)
			_man.rotation.y = lerp_angle(_man.rotation.y, -PI / 2.0, 0.1)
		position.x = spot.x
		position.z = spot.z
		if _pose:
			_pose.mode = _pose.Mode.ROW if arrive < 1.0 else _pose.Mode.IDLE
	position.y = SEA + sin(_time * 1.1) * 0.06
	rotation.z = sin(_time * 0.7) * 0.03
