extends SceneTree
## Headless test of the first-person hands: exists, follows the hotbar (empty, can, flashlight, weapon) and walking, hides with a panel.
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
	elif _frame == 5:
		_check(_hands.visible, "visible in play")
		_check(_hands.current_animation() == "idle", "empty hotbar: idle, got " + _hands.current_animation())
		Input.action_press("move_forward")
	elif _frame == 35:
		_check(_hands.current_animation() == "andar_vazio", "walks empty-handed (no flashlight yet), got " + _hands.current_animation())
		Input.action_release("move_forward")
		_main.get_node("Player").velocity = Vector3.ZERO
		state.give("oil", 1) # lands in hotbar slot 1, which is selected
	elif _frame == 60:
		_hands._on_finished() # the "pegar" reach
		_check(state.held_item() == "oil", "the can is in hand")
		_check(_hands.current_animation() == "segurar_lata", "holds the can, got " + _hands.current_animation())
		Input.action_press("move_forward")
	elif _frame == 90:
		_check(_hands.current_animation() == "andar_lata", "walks with the can, got " + _hands.current_animation())
		Input.action_release("move_forward")
		_main.get_node("Player").velocity = Vector3.ZERO
		state.give("flashlight", 1)
		state.select_hotbar(1)
	elif _frame == 115:
		_hands._on_finished()
		_check(state.held_item() == "flashlight", "flashlight selected")
		_check(_hands.current_animation() == "lanterna_idle", "holds the flashlight, got " + _hands.current_animation())
		state.flashlight_on = true
		state.flashlight_toggled.emit(true)
	elif _frame == 117:
		_check(_hands.current_animation() == "lanterna_ligar", "plays lanterna_ligar, got " + _hands.current_animation())
	elif _frame == 160:
		_hands._on_finished() # headless frames are too fast for the clip to end by itself
		_check(_hands.current_animation() == "lanterna_idle", "settles on lanterna_idle, got " + _hands.current_animation())
		Input.action_press("move_forward")
	elif _frame == 190:
		_check(_hands.current_animation() == "andar", "walks with the flashlight, got " + _hands.current_animation())
		_check(_hands._lit, "lit lens frames while on")
		Input.action_press("sprint")
	elif _frame == 220:
		_check(_hands.current_animation() == "correr", "runs, got " + _hands.current_animation())
		state.flashlight_on = false
		state.select_hotbar(2) # empty slot
	elif _frame == 222:
		_check(_hands.current_animation() == "correr_vazio", "runs empty-handed, got " + _hands.current_animation())
		state.give("axe", 1) # lands in the selected (empty) slot: drawn at once
	elif _frame == 224:
		_check(state.equipped == "axe", "an axe landing in the selected slot is drawn")
		_check(_hands._sprite.flip_h and _hands.held_kind() == "flashlight", "armed: the flashlight hand mirrors left")
		state.select_hotbar(2)
		_check(state.equipped == "", "pressing the selected weapon slot again holsters it")
		state.select_hotbar(2)
		_check(state.equipped == "axe", "and again draws it")
		state.select_hotbar(0)
	elif _frame == 250:
		_check(state.equipped == "" and not _hands._sprite.flip_h, "another slot puts the axe away")
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
