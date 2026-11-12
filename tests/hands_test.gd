extends SceneTree
## Headless test of the first-person hands: exists, switches animation with flashlight/walking, hides with a panel.
## Run: godot-4 --headless --path . --script res://tests/hands_test.gd

var _frame := 0
var _failures := 0
var _main: Node
var _hands: Node


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _process(_delta: float) -> bool:
	_frame += 1
	var state := root.get_node("GameState")
	if _frame == 1:
		_main = load("res://main.tscn").instantiate()
		root.add_child(_main)
	elif _frame == 3:
		_hands = _main.get_node_or_null("Hands")
		_check(_hands != null, "Hands node exists")
		if _hands == null:
			quit(1)
			return true
		_check(_hands.layer < _main.get_node("PsxPost").layer, "hands below PsxPost")
		_check(_hands.layer < _main.get_node("Hud").layer, "hands below HUD")
		state.begin_play()
		state.has_flashlight = true
	elif _frame == 5:
		_check(_hands.visible, "visible in play")
		state.flashlight_on = true
		state.flashlight_toggled.emit(true)
	elif _frame == 7:
		_check(_hands.current_animation() == "lanterna_ligar", "plays lanterna_ligar, got " + _hands.current_animation())
	elif _frame == 60:
		_hands._on_finished() # headless frames are too fast for the clip to end by itself
		_check(_hands.current_animation() == "lanterna_idle", "settles on lanterna_idle, got " + _hands.current_animation())
		Input.action_press("move_forward")
	elif _frame == 90:
		_check(_hands.current_animation() == "andar", "walks, got " + _hands.current_animation())
		Input.action_press("sprint")
	elif _frame == 120:
		_check(_hands.current_animation() == "correr", "runs, got " + _hands.current_animation())
		Input.action_release("move_forward")
		Input.action_release("sprint")
		var panel := Node.new()
		state.set_panel_open(panel, true)
		_check(not _hands.visible, "hidden with a panel open")
		state.set_panel_open(panel, false)
		_check(_hands.visible, "visible again after the panel closes")
		root.get_node("Settings").values["hands"] = false
		_hands._refresh()
		_check(not _hands.visible, "hidden by the option")
		root.get_node("Settings").values["hands"] = true
		if _failures > 0:
			printerr("HANDS TEST FAILED")
			quit(1)
		else:
			print("HANDS TEST PASSED")
			quit(0)
	return false
