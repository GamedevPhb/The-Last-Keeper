extends SceneTree
## Headless test of the night-gated structures: gathering, fishing, workshop, garden, watchtower, fence.
## Run: godot-4 --headless --path . --script res://tests/structures_test.gd

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
		printerr("STRUCTURES TEST FAILED: timeout")
		quit(1)
		return true
	if _frames < 3:
		return false
	_run()
	if _failures > 0:
		printerr("STRUCTURES TEST FAILED: %d check(s)" % _failures)
		quit(1)
	else:
		print("STRUCTURES TEST OK")
		quit(0)
	return true


func _use(station: Node) -> void:
	station.get_node("Use").interacted.emit(null)


func _run() -> void:
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var exp := main.get_node("Island/Expansion")
	var st := exp.get_node("Stations")
	var fishing: Node = st.get_node("Station_Fishing")
	var workshop: Node = st.get_node("Station_Workshop")
	var garden: Node = st.get_node("Station_Garden")
	var tower: Node = st.get_node("Station_Watchtower")
	var fence: Node = st.get_node("Station_Fence")
	var wood_node: Node = exp.get_node("Resources/ResNode_wood_1")
	var coal_node: Node = exp.get_node("Resources/ResNode_coal_1")
	state.begin_play()
	state.inventory.clear()

	# The table.
	for id: String in ["gather", "fishing", "workshop"]:
		_check(state.UNLOCKS[id] == 2, "%s from night 2" % id)
	for id: String in ["cistern", "garden", "watchtower", "fortify"]:
		_check(state.UNLOCKS[id] == 3, "%s from night 3" % id)

	# Night 1: only the basic gathering.
	state.night = 1
	for s: Node in [fishing, workshop, garden, tower, fence, wood_node, coal_node]:
		s._apply()
	_check(wood_node.visible and wood_node.get_node("Gather").enabled, "wood can be gathered on night 1")
	_check(not coal_node.visible and not coal_node.get_node("Gather").enabled, "coal waits for night 2")
	coal_node._on_gathered(null)
	_check(state.inventory.count("coal") == 0, "a locked node yields nothing")
	wood_node._on_gathered(null)
	_check(state.inventory.count("wood") == wood_node.amount, "wood gathered on night 1")
	for s: Node in [fishing, workshop, garden, tower, fence]:
		_check(not s.is_open() and not s.get_node("Use").enabled and not s.get_node("Body").visible, "%s is inert on night 1" % s.name)
	_use(fishing)
	_check(state.inventory.count("fish") == 0, "a closed station does nothing")

	# Night 2: coal, scrap, fishing, workshop.
	state.night = 2
	for s: Node in [fishing, workshop, garden, coal_node]:
		s._apply()
	_check(coal_node.visible and coal_node.get_node("Gather").enabled, "coal opens on night 2")
	coal_node._on_gathered(null)
	_check(state.inventory.count("coal") == coal_node.amount, "coal gathered on night 2")
	_check(fishing.is_open() and workshop.is_open() and not garden.is_open(), "night 2 opens fishing and workshop, not the garden")
	_use(fishing)
	_use(fishing)
	var fish: int = state.inventory.count("fish")
	_check(fish >= 2, "two hauls give fish (%d)" % fish)
	_check(fishing.uses_left() == 0 and not fishing.get_node("Use").enabled, "the trap is on cooldown after its nightly uses")
	_use(fishing)
	_check(state.inventory.count("fish") == fish, "no fish while on cooldown")
	var saved: Dictionary = fishing.save_state()
	fishing.uses = 0
	fishing.uses_night = 0
	fishing.load_state(saved)
	_check(fishing.uses_left() == 0, "fishing cooldown survives save/load")
	state.night = 3
	_check(fishing.uses_left() == fishing.per_night, "the trap re-arms the next night")
	state.night = 2

	state.inventory.clear()
	_check(not workshop.craft(2), "no recipe without materials")
	state.inventory.add("scrap", 5)
	state.inventory.add("coal", 3)
	_check(workshop.craft(2) and state.inventory.count("battery") == 1, "the workshop makes a battery")
	_check(state.inventory.count("scrap") == 4 and state.inventory.count("coal") == 2, "the battery costs 1 scrap + 1 coal")
	_check(workshop.craft(3) and state.inventory.count("lens_cleaner") == 1, "the workshop makes a lens cleaner")
	_check(workshop.craft(0) and state.inventory.count("ammo_pistol") == 6, "the workshop makes pistol ammo")
	_check(not workshop.craft(1), "shells need more scrap than left")
	var player: Node = main.get_node("Player")
	workshop._use(player)
	_check(workshop._console != null and workshop._console.is_open() and player.locked, "the workshop opens its console")
	workshop._console.close()
	_check(not player.locked, "closing the workshop frees the player")

	# Night 3: garden, watchtower, fence.
	state.night = 3
	for s: Node in [garden, tower, fence]:
		s._apply()
	_check(garden.is_open() and tower.is_open() and fence.is_open(), "night 3 opens garden, tower and fence")
	state.inventory.clear()
	_use(garden)
	_check(state.inventory.count("biscuit") > 0 and state.inventory.count("water") > 0, "the garden gives food and water")
	var biscuits: int = state.inventory.count("biscuit")
	_use(garden)
	_check(state.inventory.count("biscuit") == biscuits and not garden.get_node("Use").enabled, "one harvest per night")

	# Watchtower: needs the radio on.
	var desk: Node = main.get_tree().get_first_node_in_group("radio_desk")
	_check(desk.forecast().is_empty(), "no forecast with the radio unpowered")
	state.generator_on = true
	state.breakers["radio"] = true
	var info: Dictionary = desk.forecast()
	_check(not info.is_empty() and info.has("bearing") and info.eta > 0.0, "the radio forecasts the next ship")
	var again: Dictionary = desk.forecast()
	_check(again.call == info.call and again.bearing == info.bearing, "the forecast is stable")
	_use(tower)
	_check(tower.get_node("Use").enabled, "the binoculars are reusable")
	desk._until_next = 0.0
	desk._spawn_call()
	_check(state.active_call.call == info.call and state.active_call.bearing == info.bearing, "the announced ship and bearing are the ones that arrive")

	# Fence.
	state.inventory.clear()
	_use(fence)
	_check(state.fence_level == 0, "the fence needs wood")
	state.inventory.add("wood", 20)
	_use(fence)
	_check(state.fence_level == 1 and state.inventory.count("wood") == 16, "level 1 costs 4 wood")
	_use(fence)
	_check(state.fence_level == 2 and not fence.get_node("Use").enabled, "level 2 covers the door and maxes out")
	var invasion: Node = main.get_node_or_null("Island/Invasion")
	if invasion == null:
		invasion = main.find_child("Invasion", true, false)
	if invasion:
		var thin: Array = invasion.waves()
		state.fence_level = 0
		var full: Array = invasion.waves()
		state.fence_level = 2
		_check(thin[0] < full[0] and thin[2] < full[2] and thin[0] >= 2, "the fence thins the waves")
	var data: Dictionary = state.to_save()
	state.fence_level = 0
	state.from_save(data)
	_check(state.fence_level == 2, "the fence level survives save/load")


func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		printerr("  FAIL: ", what)
		_failures += 1
