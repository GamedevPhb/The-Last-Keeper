extends SceneTree
## Headless test of stamina (GDD 4.10): sprint drain, winded lock until 30, pause + regen
## (walking / standing), low needs, jump cost, save round trip, the Player sprinting with it and
## the HUD bar showing only while not full.
## Run: godot-4 --headless --path . --script res://tests/stamina_test.gd

var _failures := 0
var _frame := 0
var _state: Node
var _player: Node
var _bar: Control


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 2:
		_state = root.get_node("GameState")
		_player = root.get_node("Main/Player")
		_bar = root.get_node("Main/Hud/Root/Stamina")
		_state.in_game = true
		_state.scene_active = false
		_test_logic()
		_test_save()
		_reset(100.0)
		Input.action_press("move_forward")
		Input.action_press("sprint")
	elif _frame == 40:
		_check(_state.sprinting, "the Player sprints with stamina")
		_check(_state.stamina < 100.0, "sprinting in the scene drains stamina, got %.1f" % _state.stamina)
		_check(_bar.visible, "HUD bar shows while not full")
		_state.stamina = 5.0
		_state.winded = true
	elif _frame == 42:
		_check(not _state.sprinting, "winded: the Player only walks")
		Input.action_release("sprint")
		Input.action_release("move_forward")
		_reset(100.0)
	elif _frame >= 44 and _frame <= 400 and not _bar.visible:
		# full again: the bar fades out over UiKit's FADE second
		return _finish()
	elif _frame > 400:
		_check(false, "HUD bar hides once stamina is full")
		return _finish()
	return false


func _finish() -> bool:
	Input.action_release("sprint")
	Input.action_release("move_forward")
	if _failures > 0:
		printerr("STAMINA TEST FAILED: %d failure(s)" % _failures)
		quit(1)
	else:
		print("STAMINA TEST PASSED")
		quit(0)
	return true


func _reset(stamina: float, thirst := 80.0, hunger := 60.0) -> void:
	_state.stamina = stamina
	_state.winded = false
	_state._stamina_pause = 0.0
	_state.thirst = thirst
	_state.hunger = hunger


## Advances stamina in 1/60 s steps (like the physics tick) for `seconds`.
func _run(seconds: float, sprinting: bool, moving: bool) -> void:
	for i in roundi(seconds * 60.0):
		_state.tick_stamina(1.0 / 60.0, sprinting and _state.can_sprint(), moving)


func _test_logic() -> void:
	_reset(100.0)
	_check(_state.can_sprint(), "full stamina: can sprint")
	_run(3.0, true, true)
	_check(absf(_state.stamina - 50.0) < 1.0, "half gone after 3 s of sprint, got %.1f" % _state.stamina)
	_run(3.1, true, true)
	_check(_state.stamina == 0.0 and _state.winded, "empty and winded after ~6 s")
	_check(not _state.can_sprint(), "winded: no sprint")

	_run(0.9, false, true)
	_check(_state.stamina == 0.0, "no regen during the 1 s pause")
	_run(0.1 + 1.4, false, true)
	_check(_state.stamina > 20.0 and _state.stamina < 30.0 and _state.winded, "still winded below 30, got %.1f" % _state.stamina)
	_run(0.2, false, true)
	_check(_state.stamina >= 30.0 and not _state.winded and _state.can_sprint(), "sprint back at 30")

	_reset(0.0)
	_state._stamina_pause = _state.STAMINA_PAUSE # as if it had just run dry
	_run(1.0 + 5.0, false, true)
	_check(_state.stamina >= 99.9, "full in ~5 s walking, got %.1f" % _state.stamina)
	_reset(0.0)
	_state._stamina_pause = _state.STAMINA_PAUSE # as if it had just run dry
	_run(1.0 + 3.5, false, false)
	_check(_state.stamina >= 99.9, "full in ~3.5 s standing still, got %.1f" % _state.stamina)
	_reset(0.0)
	_state._stamina_pause = _state.STAMINA_PAUSE # as if it had just run dry
	_run(1.0 + 3.0, false, false)
	_check(_state.stamina < 99.0, "not full before 3.5 s standing")

	_reset(100.0, 20.0, 60.0)
	_run(2.0, true, true)
	_check(absf(_state.stamina - 50.0) < 1.0, "thirst < 25: drain x1.5, got %.1f" % _state.stamina)
	_reset(0.0, 80.0, 20.0)
	_state._stamina_pause = _state.STAMINA_PAUSE
	_run(1.0 + 5.0, false, true)
	_check(absf(_state.stamina - 60.0) < 1.0, "hunger < 25: regen x0.6, got %.1f" % _state.stamina)

	_reset(100.0)
	_state.stamina_jump()
	_check(is_equal_approx(_state.stamina, 90.0), "a jump costs 10")
	_run(0.5, false, false)
	_check(is_equal_approx(_state.stamina, 90.0), "a jump also restarts the pause")
	_reset(8.0)
	_state.stamina_jump()
	_check(_state.stamina == 0.0 and _state.winded, "jumping on the last breath winds")


func _test_save() -> void:
	_reset(12.0)
	_state.winded = true
	var saved: Dictionary = _state.to_save()
	_reset(100.0)
	_state.from_save(saved)
	_check(is_equal_approx(_state.stamina, 12.0) and _state.winded, "stamina and winded survive a save")
	saved.erase("stamina")
	saved.erase("winded")
	_state.from_save(saved)
	_check(_state.stamina == 100.0 and not _state.winded, "old saves load with full stamina")
	_state.reset()
	_check(_state.stamina == 100.0 and not _state.winded, "a new night starts rested")
	_state.in_game = true


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + message)
