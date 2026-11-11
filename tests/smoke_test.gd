extends SceneTree
## Headless smoke test: the keeper climbs the lighthouse ramp to the lantern
## room and toggles the lamp through the interaction system.
## Run: godot-4 --headless --path . --script res://tests/smoke_test.gd

const TOWER_CENTER := Vector3(0, 0, -12)
const RAMP_RADIUS := 2.05
const TOP_FLOOR := 16.0
const TIMEOUT := 60.0

var _player: Player
var _beacon: Beacon
var _elapsed := 0.0
var _phase := "climb"
var _failed := false


func _initialize() -> void:
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	_player = main.get_node("Player")
	_beacon = main.get_node("Island/Lighthouse/Beacon")
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
			var to_lamp := _beacon.global_position - head.global_position
			head.rotation.x = atan2(to_lamp.y, Vector2(to_lamp.x, to_lamp.z).length())
			_phase = "interact"
			Input.action_press("interact")
		"interact":
			if not _beacon.lit:
				print("lamp toggled off via hold interaction at %.1fs" % _elapsed)
				Input.action_release("interact")
				return _finish("")
	return false


func _steer_along_ramp() -> void:
	var offset := _player.global_position - TOWER_CENTER
	offset.y = 0.0
	var radial := offset.normalized()
	var tangent := Vector3(-radial.z, 0, radial.x)
	var direction := (tangent + radial * (RAMP_RADIUS - offset.length())).normalized()
	_player.rotation.y = atan2(-direction.x, -direction.z)


func _finish(error: String) -> bool:
	if error.is_empty():
		print("SMOKE TEST PASSED")
	else:
		printerr("SMOKE TEST FAILED: " + error)
		_failed = true
	Input.action_release("move_forward")
	Input.action_release("interact")
	quit(1 if _failed else 0)
	return true
