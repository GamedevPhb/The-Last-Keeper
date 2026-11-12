extends SceneTree
## Headless smoke test: the keeper climbs the lighthouse ramp to the lantern room, opens
## the lamp console through the interaction system and drives it with simulated input:
## refuel, pump, heat, open (lit), close, drown, then close the panel.
## Run: godot-4 --headless --path . --script res://tests/smoke_test.gd

const TOWER_CENTER := Vector3(0, 0, -12)
const RAMP_RADIUS := 2.05
const TOP_FLOOR := 16.0
const TIMEOUT := 90.0

var _player ## the Player (untyped: its class needs autoloads the test cannot see)
var _beacon: Node
var _elapsed := 0.0
var _phase := "climb"
var _failed := false
var _state: Node
var _console: Node
var _wait := 0.0
var _taps := 0
var _open_minutes := 0.0
var _peak_pressure := 0.0


func _initialize() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	_player = main.get_node("Player")
	_beacon = main.get_node("Island/Lighthouse/Beacon")
	_state = root.get_node("GameState")
	var start_angle := deg_to_rad(-10.0)
	# Main is a plain Node, so local position == global (tree isn't ready yet).
	_player.position = TOWER_CENTER + Vector3(cos(start_angle), 0, sin(start_angle)) * RAMP_RADIUS + Vector3.UP * 0.1
	Input.action_press("move_forward")


func _physics_process(delta: float) -> bool:
	_elapsed += delta
	if _elapsed > TIMEOUT:
		return _finish("timeout in phase '%s' at %s" % [_phase, _player.global_position])

	match _phase:
		"climb":
			_steer_along_ramp()
			if _player.global_position.y > TOP_FLOOR - 0.1 and _player.is_on_floor():
				print("climbed to %.2f in %.1fs" % [_player.global_position.y, _elapsed])
				Input.action_release("move_forward")
				_phase = "aim"
		"aim":
			# Stand still and look straight at the lamp from the floor.
			_player.velocity = Vector3.ZERO
			_player.look_at(Vector3(_beacon.global_position.x, _player.global_position.y, _beacon.global_position.z))
			var head: Node3D = _player.get_node("Head")
			var to_lamp: Vector3 = _beacon.global_position - head.global_position
			head.rotation.x = atan2(to_lamp.y, Vector2(to_lamp.x, to_lamp.z).length())
			_state.oil_cans = 1
			_phase = "open"
			Input.action_press("interact")
		"open":
			_console = _beacon.get("_console")
			if _console and _console.is_open():
				Input.action_release("interact")
				if not _player.locked:
					return _finish("console open but the player is not locked")
				if _player.get_parent().get_node("Hud/Root").visible:
					return _finish("the HUD stays on top of the open console")
				print("console opened via interaction at %.1fs" % _elapsed)
				_open_minutes = _state.minutes
				_key(KEY_1, true)
				_phase = "fill"
		"fill":
			if _beacon.oil >= 50.0:
				_key(KEY_1, false)
				print("refuelled by holding 1 at %.1fs" % _elapsed)
				_phase = "pump"
		"pump":
			_wait -= delta
			if _wait <= 0.0:
				_key(KEY_3, _taps % 2 == 0)
				_taps += 1
				_wait = 0.15
			if _beacon.pressure >= 62.0:
				_key(KEY_3, false)
				_peak_pressure = _beacon.pressure
				# Walk the focus from BOMBEAR to AQUECER and hold X/Space.
				_action("ui_left", true)
				_action("ui_left", false)
				_action("jump", true)
				_phase = "heat"
		"heat":
			if _beacon.temp >= 72.0:
				_action("jump", false)
				_key(KEY_4, true)
				_key(KEY_4, false)
				_phase = "lit"
		"lit":
			if not _beacon.lit:
				return _finish("the lamp did not light after pump, heat, open")
			print("lamp lit through the console at %.1fs" % _elapsed)
			_key(KEY_4, true)
			_key(KEY_4, false)
			_phase = "cool"
		"cool":
			if _beacon.lit:
				return _finish("closing the valve did not put the lamp out")
			if _beacon.temp < 60.0:
				_key(KEY_4, true)
				_key(KEY_4, false)
				_phase = "drowned"
		"drowned":
			if _beacon.lit or _beacon.valve_lock <= 0.0:
				return _finish("opening cold did not drown the burner")
			if _state.minutes <= _open_minutes or _beacon.pressure >= _peak_pressure:
				return _finish("the night stopped while the console was open")
			print("drowned when opened cold; clock ran %.1f min with the panel open" % (_state.minutes - _open_minutes))
			_key(KEY_Q, true)
			_key(KEY_Q, false)
			_phase = "closed"
		"closed":
			if _console.is_open() or _player.locked:
				return _finish("Q did not close the console")
			_wait = 2.0
			_phase = "settle"
		"settle":
			# Let one-shot sounds and smoke finish so nothing is mid-flight at exit.
			_wait -= delta
			if _wait <= 0.0:
				return _finish("")
	return false


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _action(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _steer_along_ramp() -> void:
	var offset: Vector3 = _player.global_position - TOWER_CENTER
	offset.y = 0.0
	var radial: Vector3 = offset.normalized()
	var tangent := Vector3(-radial.z, 0, radial.x)
	var direction: Vector3 = (tangent + radial * (RAMP_RADIUS - offset.length())).normalized()
	_player.rotation.y = atan2(-direction.x, -direction.z)


func _finish(error: String) -> bool:
	if error.is_empty():
		print("SMOKE TEST PASSED")
	else:
		printerr("SMOKE TEST FAILED: " + error)
		_failed = true
	Input.action_release("move_forward")
	Input.action_release("interact")
	if _console:
		_console.close()
	quit(1 if _failed else 0)
	return true
