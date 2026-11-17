extends SceneTree
## Headless test of the invasion: clock trigger, three waves that spawn and end when killed, the
## ammunition crate (once), the book note, the HUD counter and the save round trip.
## Run: godot-4 --headless --path . --script res://tests/invasion_test.gd

var _failures := 0
var _frame := 0


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 3:
		return false
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var inv: Node3D = main.find_child("Invasion", true, false)
	_check(inv != null, "the island has an Invasion node")
	if inv == null:
		quit(1)
		return true
	state.night = 2 # the full 4-6-8 waves (night 1 is gentler, see night_test.gd)
	state.in_game = true
	state.finished = false
	state.minutes = 26.0 * 60.0 + 29.0
	inv._physics_process(0.5)
	_check(not state.invasion_active, "no invasion before 02:30")
	var pickups_before := root.get_tree().get_nodes_in_group("pickups").size()
	state.minutes = 26.0 * 60.0 + 30.0
	inv._physics_process(0.5)
	_check(state.invasion_active and state.invasion_wave == 0, "the invasion starts at 02:30 with the warning")
	_check(state.invasion_crate and root.get_tree().get_nodes_in_group("pickups").size() > pickups_before, "ammo crate appears")
	var crate_count := root.get_tree().get_nodes_in_group("pickups").size()
	_check(state.notes.size() > 0 and state.notes[-1].contains("O mar devolveu algo"), "the book has the warning")
	var tension_quiet: float = state.tension()
	_check(tension_quiet > 0.2, "tension rises during the invasion")

	var counts := [4, 6, 8]
	for wave in 3:
		_step(inv, 14.0 if wave == 0 else 11.0)
		_step(inv, 0.5, 14)
		_check(state.invasion_wave == wave + 1, "wave %d starts" % (wave + 1))
		_check(inv.foes().size() == counts[wave] and state.invasion_left == counts[wave], "wave %d has %d foes, got %d" % [wave + 1, counts[wave], inv.foes().size()])
		if wave == 2:
			var tough := 0
			for foe in inv.foes():
				tough += int(foe.health > 100.0 and foe.speed_scale >= 1.3)
			_check(tough == 1, "the last wave has one tough Lavado")
			var saved: Dictionary = state.to_save()
			_check(saved.invasion_active and saved.invasion_wave == 3 and not saved.invasion_done, "save keeps the wave")
			state.invasion_wave = 0
			state.invasion_active = false
			state.from_save(saved)
			_check(state.invasion_active and state.invasion_wave == 3, "load restores the wave")
		for foe in inv.foes().duplicate():
			_check(foe.invader and foe.is_in_group("enemies"), "foe is an invader in the enemies group")
			foe.take_damage(500.0)
		_step(inv, 0.5)
		_check(state.invasion_left == 0, "wave %d cleared" % (wave + 1))
	_step(inv, 0.5)
	_check(state.invasion_done and not state.invasion_active, "the invasion ends when the last wave falls")
	_check(state.invasion_kills == 18, "18 kills, got %d" % state.invasion_kills)
	_check(state.notes[-1].begins_with("A maré recuou"), "the book records the ebb")
	_check(state.invasion_summary().contains("recuou"), "summary mentions the ebb")
	_check(root.get_tree().get_nodes_in_group("pickups").size() == crate_count, "the crate came only once")
	state.minutes = 26.0 * 60.0 + 31.0
	_step(inv, 0.5)
	_check(not state.invasion_active, "it does not start again")
	var saved: Dictionary = state.to_save()
	_check(saved.invasion_done and saved.invasion_kills == 18, "done flag and kills saved")

	if _failures > 0:
		printerr("INVASION TEST FAILED: %d" % _failures)
		quit(1)
	else:
		print("INVASION TEST PASSED")
		quit(0)
	return true


func _step(inv: Node, delta: float, times := 1) -> void:
	for i in times:
		inv._physics_process(delta)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)
