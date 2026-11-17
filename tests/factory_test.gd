extends SceneTree
## Headless test of the converter stations, gather nodes, UNLOCKS and `near` scene triggers.
## Run: godot-4 --headless --path . --script res://tests/factory_test.gd

const TIMEOUT := 60.0

var _failures := 0
var _elapsed := 0.0
var _frames := 0


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _process(delta: float) -> bool:
	_elapsed += delta
	_frames += 1
	if _elapsed > TIMEOUT:
		printerr("FACTORY TEST FAILED: timeout")
		quit(1)
		return true
	if _frames < 3:
		return false
	_run()
	if _failures > 0:
		printerr("FACTORY TEST FAILED: %d check(s)" % _failures)
		quit(1)
	else:
		print("FACTORY TEST OK")
		quit(0)
	return true


func _run() -> void:
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var stations := main.get_node("Island/Details/Stations")
	var player: Node = main.get_node("Player")
	state.begin_play()
	var oil: Node = stations.get_node("OilFactory")
	var fuel: Node = stations.get_node("FuelFactory")
	state.inventory.clear()

	# Unlocks by night.
	_check(state.unlocked("oil_factory") and not state.unlocked("gather"), "night 1 unlocks the factories only")
	state.night = 2
	_check(state.unlocked("gather") and not state.unlocked("watchtower"), "night 2 unlocks gathering")
	state.night = 1

	# Deposit rules.
	_check(oil.deposit("wood", 1) == 0, "empty bag deposits nothing")
	state.inventory.add("wood", 10)
	state.inventory.add("coal", 5)
	_check(oil.deposit("coal", 3) == 0, "the oil factory refuses coal")
	_check(fuel.deposit("coal", 3) == 3 and fuel.stock == 3, "the fuel factory takes coal")
	var room: int = oil.stock_room()
	_check(oil.deposit("wood", 99) == 10 and oil.stock == 10 and oil.stock_room() == room - 10, "deposit takes what the bag has")

	# Production: freezes during a panel, runs otherwise.
	var per: int = oil.inputs_per_unit
	_check(oil.stock >= per, "enough stock for one unit")
	state.panel_open = true
	oil._process(oil.seconds_per_unit + 1.0)
	_check(oil.ready_units == 0, "production freezes while a panel is open")
	state.panel_open = false
	oil._process(oil.seconds_per_unit + 1.0)
	_check(oil.ready_units == 1 and oil.stock == 10 - per, "one unit is made after seconds_per_unit")
	state.scene_active = true
	oil._process(oil.seconds_per_unit + 1.0)
	_check(oil.ready_units == 1, "production freezes during a story scene")
	state.scene_active = false

	# Save / load.
	var saved: Dictionary = oil.save_state()
	oil.ready_units = 0
	oil.stock = 0
	oil.load_state(saved)
	_check(oil.ready_units == 1 and oil.stock == 10 - per, "factory state survives save/load")

	# Collect.
	var before: int = state.inventory.count("oil")
	_check(oil.collect() == 1 and state.inventory.count("oil") == before + 1, "collect hands over the oil can")
	_check(oil.collect() == 0, "nothing left to collect")

	# Console by simulated presses.
	state.inventory.add("wood", 5)
	var wood_before: int = state.inventory.count("wood")
	oil._on_interacted(player)
	var console: Node = oil._console
	_check(console != null and console.is_open() and player.locked, "the factory opens its console and locks the player")
	console.press(0)
	_check(state.inventory.count("wood") == wood_before - 1, "pressing the first button deposits wood")
	console.press(oil.input_items.size())
	console.close()
	_check(not player.locked and not state.panel_open, "closing the console frees the player")

	# Gather node.
	var node := Marker3D.new()
	node.set_script(load("res://world/resource_node.gd"))
	node.kind = "algae"
	node.amount = 3
	main.add_child(node)
	var algae_before: int = state.inventory.count("algae")
	node._on_gathered(player)
	_check(state.inventory.count("algae") == algae_before + 3 and node.is_spent(), "a gather node yields its amount and is spent")
	var node_saved: Dictionary = node.save_state()
	node.spent_night = -999
	node.load_state(node_saved)
	_check(node.is_spent(), "a spent node stays spent after load")
	state.night = 2
	_check(not node.is_spent(), "a node re-arms the next night")
	state.night = 1

	# `near` triggers.
	var asked: Array[String] = []
	state.scene_requested.connect(func(id: String) -> void: asked.append(id))
	state.scenes_seen = {}
	player.global_position = Vector3(0.0, 0.5, -10.0)
	state._check_scenes(1.0)
	_check(asked == ["tut_lamp"], "walking up to the lighthouse asks for tut_lamp")
	state._check_scenes(1.0)
	_check(asked.size() == 1, "a near scene fires once")
	state.advance_night()
	_check(state.scenes_seen.get("tut_lamp", false), "tut_ scenes survive advance_night")
	asked.clear()
	player.global_position = Vector3(-12.0, 0.5, 21.5)
	state.scene_active = false
	state.panel_open = false # advance_night leaves the tracked-panel flag to the overlay
	state._check_scenes(1.0)
	_check(asked == ["tut_oil_factory"], "the oil factory scene fires near it (got %s)" % str(asked))
	for id: String in ["tut_lamp", "tut_generator", "tut_oil_factory", "tut_fuel_factory"]:
		_check(root.get_node("GameState").SCENE_TRIGGERS.has(id) and load("res://ui/story_scene.gd").SCENES.has(id), "%s has a trigger and a scene" % id)


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		printerr("  FAIL: ", what)
		_failures += 1
