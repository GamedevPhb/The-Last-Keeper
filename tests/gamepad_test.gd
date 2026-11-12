extends SceneTree
## Headless test of gamepad buttons: action mapping (A/B/X/Start) and the main menu being operable without a mouse.
## Run: godot-4 --headless --path . --script res://tests/gamepad_test.gd

var _frame := 0
var _failures := 0
var _menu: Node


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _button(index: int, pressed: bool = true) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = index
	event.pressed = pressed
	return event


func _motion(axis: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = value
	return event


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 1:
		_check(_button(0).is_action("ui_accept"), "A -> ui_accept")
		_check(_button(2).is_action("ui_accept"), "X/Square -> ui_accept")
		_check(_button(6).is_action("ui_accept"), "Start -> ui_accept")
		_check(_button(1).is_action("ui_cancel"), "B -> ui_cancel")
		_check(_button(0).is_action("interact"), "A -> interact")
		_check(_button(2).is_action("interact"), "X/Square -> interact")
		_check(_button(6).is_action("pause"), "Start -> pause")
		_check(_button(1).is_action("jump"), "B -> jump")
		_check(not _button(0).is_action("jump"), "A does not jump")
		_check(_motion(7, -1.0).is_action("ui_up"), "hat axis 7 -> ui_up")
		_check(_motion(6, 1.0).is_action("ui_right"), "hat axis 6 -> ui_right")
		_check(_button(12).is_action("ui_down"), "dpad down -> ui_down")
		_menu = load("res://ui/main_menu.tscn").instantiate()
		root.add_child(_menu)
	elif _frame == 4:
		var buttons: VBoxContainer = _menu._buttons
		var first := buttons.get_child(0) as Button
		_check(root.gui_get_focus_owner() == first, "main menu focuses the first button")
		_check(not _menu._slots.visible, "slots hidden before confirm")
		Input.parse_input_event(_button(0))
		Input.parse_input_event(_button(0, false))
	elif _frame == 6:
		_check(_menu._slots.visible, "A on 'Novo jogo' opens the slot screen")
		Input.parse_input_event(_button(1))
		Input.parse_input_event(_button(1, false))
	elif _frame == 8:
		_check(not _menu._slots.visible, "B closes the slot screen")
		_check(root.gui_get_focus_owner() == _menu._buttons.get_child(0), "focus returns to first button")
		print("gamepad_test: %s" % ("OK" if _failures == 0 else "%d failure(s)" % _failures))
		quit(1 if _failures > 0 else 0)
	return false
