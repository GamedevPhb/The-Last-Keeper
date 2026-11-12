extends SceneTree
## Headless test of thirst, hunger and health (GDD 4.10, criterion 7): rates, thresholds, regen, critical icons.
## Only needs the GameState autoload; the in-scene death summary stays in puzzle_test.gd.
## Run: godot-4 --headless --path . --script res://tests/status_test.gd

var _failures := 0
var _ran := false
var _state: Node


func _process(_delta: float) -> bool:
	if _ran:
		return true
	_ran = true
	_state = root.get_node("GameState")
	_state.keepers_path = "user://keepers_test.cfg"
	_reset()
	_test_rates()
	_test_zero_times()
	_test_zero_damage()
	_test_regen()
	_test_critical()
	_test_water_and_death()
	if _failures > 0:
		printerr("STATUS TEST FAILED: %d failure(s)" % _failures)
		quit(1)
	else:
		print("STATUS TEST PASSED")
		quit(0)
	return true


func _hour() -> float:
	return 60.0 * _state.SECONDS_PER_MINUTE


func _reset(thirst := 80.0, hunger := 60.0, health := 100.0) -> void:
	_state.thirst = thirst
	_state.hunger = hunger
	_state.health = health
	_state.dead = false
	_state.death_cause = ""
	_state.sprinting = false
	_state.in_water = false
	_state.cold_left = 0.0
	_state.minutes = float(_state.START_MINUTES)


func _test_rates() -> void:
	_check(_state.thirst == 80.0 and _state.hunger == 60.0 and _state.health == 100.0, "starting values 80/60/100")
	_state.tick_status(_hour())
	_check(is_equal_approx(_state.thirst, 72.0), "thirst -8/h")
	_check(is_equal_approx(_state.hunger, 55.0), "hunger -5/h")
	_check(is_equal_approx(_state.health, 100.0), "health does not drop with needs above 0")
	_state.sprinting = true
	_state.tick_status(_hour())
	_check(is_equal_approx(_state.thirst, 60.0), "sprinting: thirst x1.5")
	_check(is_equal_approx(_state.hunger, 50.0), "sprinting does not change hunger")
	_reset()
	_state.minutes = float(_state.COLD_FROM) + 1.0
	_state.tick_status(_hour())
	_check(is_equal_approx(_state.hunger, 60.0 - 5.0 * 1.5), "hunger x1.5 outdoors after 02:00")
	_state.minutes = float(_state.COLD_FROM) - 1.0
	_reset()
	_state.minutes = float(_state.COLD_FROM) - 1.0
	_state.tick_status(_hour())
	_check(is_equal_approx(_state.hunger, 55.0), "hunger normal before 02:00")


func _test_zero_times() -> void:
	_reset()
	for i in 99:
		_state.tick_status(_hour() / 10.0)
	_check(_state.thirst > 0.0, "thirst above 0 just before 10 h")
	_state.tick_status(_hour() / 10.0 + 0.01)
	_check(_state.thirst == 0.0, "thirst empties after 10 h (17:30 -> 03:30)")
	_reset(100.0, 60.0)
	for i in 119:
		_state.tick_status(_hour() / 10.0)
	_check(_state.hunger > 0.0, "hunger above 0 just before 12 h (indoors rate)")
	_state.tick_status(_hour() / 10.0 + 0.01)
	_check(_state.hunger == 0.0, "hunger empties after 12 h at the base rate")


func _test_zero_damage() -> void:
	_reset(0.0, 60.0, 100.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE)
	_check(is_equal_approx(_state.health, 99.0), "thirst 0: -1 health per game minute")
	_check(not _state.can_sprint(), "thirst 0 blocks sprint")
	_reset(80.0, 0.0, 100.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE)
	_check(is_equal_approx(_state.health, 99.7), "hunger 0: -0.3 health per game minute")
	_check(not _state.can_sprint(), "hunger 0 blocks sprint")
	_reset()
	_check(_state.can_sprint(), "sprint allowed with needs above 0")
	_reset(0.0, 0.0, 100.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE)
	_check(is_equal_approx(_state.health, 98.7), "thirst and hunger at 0 stack (-1.3/min)")
	_reset(0.0, 60.0, 0.5)
	_state.tick_status(_state.SECONDS_PER_MINUTE)
	_check(_state.dead and _state.death_cause == "A sede", "dying of thirst reports 'A sede'")


func _test_regen() -> void:
	_reset(80.0, 60.0, 60.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE * 2.0)
	_check(_state.health > 61.9 and _state.health < 62.1, "regen +1 health per game minute when both >= 50")
	_state.tick_status(_state.SECONDS_PER_MINUTE * 60.0)
	_check(is_equal_approx(_state.health, 70.0), "regen stops at 70")
	_reset(80.0, 60.0, 90.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE * 5.0)
	_check(is_equal_approx(_state.health, 90.0), "no regen above 70 (only bandage)")
	_reset(49.0, 60.0, 50.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE)
	_check(is_equal_approx(_state.health, 50.0), "no regen with thirst < 50")
	_reset(80.0, 49.0, 50.0)
	_state.tick_status(_state.SECONDS_PER_MINUTE)
	_check(is_equal_approx(_state.health, 50.0), "no regen with hunger < 50")


func _test_critical() -> void:
	_reset(21.0, 21.0, 31.0)
	_state.tick_status(0.0)
	var c: Dictionary = _state.critical()
	_check(not c["thirst"] and not c["hunger"] and not c["health"], "no icons above 20/20/30")
	_reset(20.0, 20.0, 30.0)
	c = _state.critical()
	_check(c["thirst"] and c["hunger"] and c["health"], "icons at 20/20/30 (<=)")
	_reset(19.0, 80.0, 100.0)
	c = _state.critical()
	_check(c["thirst"] and not c["hunger"] and not c["health"], "only thirst critical")
	_reset(80.0, 19.0, 100.0)
	c = _state.critical()
	_check(not c["thirst"] and c["hunger"], "only hunger critical")
	_reset(19.0, 19.0, 100.0)
	_state.thirst = 60.0
	c = _state.critical()
	_check(not c["thirst"], "icon disappears when thirst recovers")


func _test_water_and_death() -> void:
	_reset()
	_state.in_water = true
	_state.tick_status(1.0)
	_check(_state.health <= 97.1 and _state.health >= 96.9, "sea: -3 health/s")
	_check(_state.cold_left > 0.0, "sea leaves the keeper cold")
	_state.in_water = false
	_reset(80.0, 60.0, 100.0)
	_state.cold_left = 10.0
	_state.tick_status(_hour())
	_check(is_equal_approx(_state.hunger, 55.0 - 5.0) or _state.hunger < 55.0, "cold speeds up hunger")
	_reset()
	_state.damage(40.0, "Algo na escada")
	_check(is_equal_approx(_state.health, 60.0) and not _state.dead, "damage lowers health")
	_state.damage(60.0, "O mar")
	_check(_state.dead and _state.death_cause == "O mar", "health 0 kills with the cause")
	_state.damage(10.0, "Outra")
	_check(_state.death_cause == "O mar", "death cause is not overwritten")
	_reset()


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + message)
