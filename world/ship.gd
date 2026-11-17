class_name Ship
extends Node3D
## One ship of the logbook (GameState.SHIPS): the shared cargo model tinted and scaled per ship,
## with its captain on deck. It waits offshore while the call rings, then acts out the verdict:
## moors by the pier (docked / liar), sails past (refused) or runs aground in the SW rocks (wrecked).

enum State { AWAY, WAIT, DOCKING, DOCKED, LEAVING, WRECKED }

const SEA := -1.2
const OFFSHORE := Vector3(30.0, SEA, 100.0)
const DOCK := Vector3(9.0, SEA, 68.0)
const FAR := Vector3(110.0, SEA, 140.0)
const REEFS := [Vector3(-34.0, SEA, 40.0), Vector3(-46.0, SEA, 36.0), Vector3(-26.0, SEA, 48.0),
	Vector3(-52.0, SEA, 46.0), Vector3(-38.0, SEA, 52.0), Vector3(-60.0, SEA, 38.0)]
const COLORS := [Color(0.75, 0.3, 0.25), Color(0.3, 0.3, 0.32), Color(0.85, 0.8, 0.6),
	Color(0.25, 0.45, 0.35), Color(0.3, 0.45, 0.7), Color(0.65, 0.5, 0.3)]
const SCALES := [0.30, 0.36, 0.28, 0.40, 0.33, 0.38]
const CAPTAINS := ["Character_17_Police", "Character_18_Police", "Character_19_Police",
	"Character_20_Police", "Character_21_Police", "Character_22_Police"]
const WAIT_DRIFT := 0.5 ## m/s toward the dock while the call rings
const DOCKED_STAY := 45.0

var call_name := ""
var state := State.AWAY
var outcome := ""
var captain: Node3D
var _index := 0
var _time := 0.0
var _stay := 0.0
var _sink := 0.0
var _lamp: OmniLight3D
var _model: Node3D
var _haunted := false


func setup(index: int, ship_name: String) -> void:
	_index = index
	call_name = ship_name
	name = ship_name
	var model := Actors.cargo(COLORS[index], 0.55, SCALES[index])
	_model = model
	add_child(model)
	captain = Actors.character(CAPTAINS[index])
	captain.position = Vector3(0.0, model.get_meta("deck_y"), model.get_meta("length") * 0.28)
	captain.rotation.y = -PI / 2.0
	add_child(captain)
	_lamp = OmniLight3D.new()
	_lamp.light_color = Color(1.0, 0.75, 0.4)
	_lamp.light_energy = 0.8
	_lamp.omni_range = 9.0
	_lamp.position = Vector3(0.0, model.get_meta("deck_y") + 3.0, 0.0)
	add_child(_lamp)
	visible = false


## Story scene "aurora": the hull goes rust-dark like the Santa Aurora's, the lamp turns pale and
## dies out, and the captain turns to face the keeper. `haunt(false)` restores the ship.
func haunt(on: bool) -> void:
	_haunted = on
	if on:
		Actors.psx_skin(_model, Color(0.28, 0.18, 0.12), 0.8)
		_lamp.light_color = Color(0.95, 0.8, 0.5)
		_lamp.light_energy = 0.6
		_lamp.visible = true
	else:
		Actors.psx_skin(_model, COLORS[_index], 0.55)
		_lamp.light_color = Color(1.0, 0.75, 0.4)
		_lamp.light_energy = 0.8


## The call rings: the ship shows up at sea and creeps toward the channel.
func announce() -> void:
	if _haunted:
		haunt(false)
	state = State.WAIT
	outcome = ""
	_sink = 0.0
	global_position = OFFSHORE
	rotation = Vector3.ZERO
	_face(DOCK - OFFSHORE, 1.0)
	captain.visible = true
	_lamp.visible = true
	visible = true


func resolve(result: String) -> void:
	if state == State.AWAY:
		announce()
	outcome = result
	match result:
		"docked", "liar":
			state = State.DOCKING
		"refused":
			state = State.LEAVING
		_:
			state = State.WRECKED
			captain.visible = false
			_lamp.visible = false


func _process(delta: float) -> void:
	if state == State.AWAY:
		return
	_time += delta
	if _haunted:
		_lamp.light_energy = maxf(_lamp.light_energy - delta * 0.07, 0.0)
		captain.visible = state == State.DOCKED
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if captain.visible and player:
			captain.look_at(Vector3(player.global_position.x, captain.global_position.y, player.global_position.z), Vector3.UP, true)
	match state:
		State.WAIT:
			_move(DOCK, WAIT_DRIFT, delta, 0.25)
		State.DOCKING:
			if _move(DOCK, 4.0, delta):
				state = State.DOCKED
				_stay = DOCKED_STAY
		State.DOCKED:
			rotation.y = lerp_angle(rotation.y, 0.0, delta)
			if outcome == "liar":
				_lamp.visible = false
			else:
				_stay -= delta
				if _stay <= 0.0:
					state = State.LEAVING
		State.LEAVING:
			if _move(FAR, 5.0, delta):
				state = State.AWAY
				visible = false
		State.WRECKED:
			var spot: Vector3 = REEFS[_index]
			if _move(spot, 4.0, delta):
				_sink = minf(_sink + delta / 20.0, 1.0)
				rotation.z = lerp_angle(rotation.z, deg_to_rad(14.0), delta)
				rotation.x = lerp_angle(rotation.x, deg_to_rad(-6.0), delta)
				position.y = SEA - 2.0 * _sink
				return
	if state != State.WRECKED:
		position.y = SEA + sin(_time * 0.9 + _index) * 0.08
		rotation.z = sin(_time * 0.6 + _index * 2.0) * 0.015


## Moves toward `goal` on the water; `fraction` stops the trip that part of the way from OFFSHORE.
func _move(goal: Vector3, speed: float, delta: float, fraction := 1.0) -> bool:
	var stop := OFFSHORE.lerp(goal, fraction) if fraction < 1.0 else goal
	var flat := Vector3(stop.x - position.x, 0.0, stop.z - position.z)
	if flat.length() < 0.2:
		return true
	_face(flat, delta * 0.8)
	var step := minf(speed * delta, flat.length())
	position += flat.normalized() * step
	return flat.length() - step < 0.2


func _face(dir: Vector3, weight: float) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), clampf(weight, 0.0, 1.0))
