extends SceneTree
## Headless test of the ships, the boatman, the Santa Aurora and the Lavados.
## Run: godot-4 --headless --path . --script res://tests/ships_test.gd

var _frame := 0
var _failures := 0
var _main: Node


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _process(_delta: float) -> bool:
	_frame += 1
	var state := root.get_node("GameState")
	var details: Node
	if _main:
		details = _main.get_node("Island/Details") if _main.has_node("Island/Details") else _find(_main, "Ships").get_parent()
	if _frame == 1:
		_main = load("res://main.tscn").instantiate()
		root.add_child(_main)
	elif _frame == 4:
		state.begin_play()
		_check(details.get_node("Boatman").visible, "boatman at the pier at 17:30")
		var man: Node3D = details.get_node("Boatman")
		_check(absf(man.position.y - (-1.2)) < 0.2, "boat on the water")
		state.active_call = {"call": "Marlin"}
	elif _frame == 6:
		var ship: Node3D = details.get_node("Ships/Marlin")
		_check(ship.visible, "Marlin shows when the call rings")
		_check(ship.captain.visible, "captain visible")
		var height := _height(ship.captain)
		_check(height > 1.4 and height < 2.2, "captain ~1.8 m, got %.2f" % height)
		state.active_call = {}
		state.ship_event.emit("Marlin", "wrecked")
		_check(ship.state == 5, "Marlin wrecks")
		state.ship_event.emit("Ceres", "refused")
		_check(details.get_node("Ships/Ceres").state == 4, "Ceres sails past")
		state.minutes = 24.0 * 60.0 + 40.0
	elif _frame == 12:
		var aurora: Node3D = details.get_node("Wreck")
		_check(aurora._windows.visible, "Santa Aurora windows lit after 00:30")
		_check(not aurora._captain.visible, "Captain hidden before 03:05")
		var lavados: Node3D = details.get_node("Lavados")
		_check(lavados.walkers().size() == 3, "3 Lavados at midnight, got %d" % lavados.walkers().size())
		var first: Node3D = lavados.walkers()[0]
		var before := first.global_position
		_check(before.y > -1.0, "Lavado on the ground, y=%.2f" % before.y)
		var horizon: Node3D = details.get_node("HorizonShip")
		var lit := 0
		for lamp in horizon._lamps:
			lit += int(lamp.visible)
		_check(lit > 10, "horizon ship lamps burn at night, got %d" % lit)
		details.get_node("Boatman").board()
		_check(not details.get_node("Boatman").visible, "boatman stays gone after boarding")
		state.minutes = 27.0 * 60.0 + 5.0
	elif _frame == 20:
		_check(details.get_node("Wreck")._captain.visible, "Captain on deck at 03:05")
		var first: Node3D = details.get_node("Lavados").walkers()[0]
		_check(first.global_position.z < 33.0 or first.global_position.x != -14.0, "Lavado advanced")
		state.minutes = 29.5 * 60.0
	elif _frame == 24:
		_check(details.get_node("Boatman").visible, "boatman returns near dawn")
		quit(1 if _failures > 0 else 0)
	if _frame == 24:
		print("ships_test: ok" if _failures == 0 else "ships_test: %d failures" % _failures)
	return false


func _find(node: Node, node_name: String) -> Node:
	return node.find_child(node_name, true, false)


func _height(node: Node3D) -> float:
	var top := -1e9
	var low := 1e9
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mi := found as MeshInstance3D
		var box := mi.global_transform * mi.get_aabb()
		top = maxf(top, box.end.y)
		low = minf(low, box.position.y)
	return top - low
