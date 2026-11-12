extends SceneTree
## Headless test of the cellar padlock console: opens through the Interactable, a wrong code
## clacks and keeps the hatch shut, then 8-3-5 typed with simulated input (W/D/interact) opens it.
## Run: godot-4 --headless --path . --script res://tests/lock_test.gd

const TIMEOUT := 30.0

var _failures := 0
var _elapsed := 0.0
var _frame := 0
var _lock: Node
var _panel: Node
var _state: Node


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _process(delta: float) -> bool:
	_elapsed += delta
	_frame += 1
	if _elapsed > TIMEOUT:
		return _finish("timeout")
	var main := root.get_node("Main")
	match _frame:
		2:
			_state = root.get_node("GameState")
			_lock = main.get_node("Island/Details/Stations/Station_Cellar")
			_lock.get_node("Lock").interact(null)
			_panel = _lock._console
			_check(_panel.is_open(), "console opens")
			_check(_state.panel_open and main.get_node("Player").locked, "panel locks the player and hides the HUD")
			_press("interact") # confirm 0-0-0: wrong
		3:
			_check(not _lock._open, "wrong code keeps the hatch shut")
			_check(_panel._wrong > 0.0, "wrong code shows feedback")
			_panel._wrong = 0.0
			_type_digit(8)
		4:
			_press("move_right")
			_type_digit(3)
		5:
			_press("move_right")
			_type_digit(5)
			_check(_panel._digits == [8, 3, 5], "digits read 8-3-5")
			_press("interact")
			_check(_panel._success > 0.0, "right code shows success")
		_:
			if _frame > 6 and not _panel.is_open():
				_check(_lock._open, "hatch opens after the code")
				_check(not _state.panel_open and not main.get_node("Player").locked, "closing frees the player")
				return _finish("")
	return false


func _type_digit(count: int) -> void:
	for _i in count:
		_press("move_forward")


func _press(action: String) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
	Input.flush_buffered_events()


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)


func _finish(error: String) -> bool:
	if error != "":
		printerr("LOCK TEST FAILED: ", error)
		quit(1)
	elif _failures > 0:
		printerr("LOCK TEST FAILED: %d checks" % _failures)
		quit(1)
	else:
		print("LOCK TEST PASSED")
		quit(0)
	return true
