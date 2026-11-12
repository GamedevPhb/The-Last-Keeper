extends SceneTree
## Headless logic test for the puzzles: lamp console, generator valves, breakers, cellar lock.
## Run: godot-4 --headless --path . --script res://tests/puzzle_test.gd

const TIMEOUT := 60.0

var _failures := 0
var _elapsed := 0.0
var _ran := false
var _last_toast := ""


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


## Runs on the first frame, once every _ready has built its interactables.
func _process(delta: float) -> bool:
	# A script error aborts the run mid-way; the watchdog still exits with a failure.
	_elapsed += delta
	if _elapsed > TIMEOUT:
		printerr("PUZZLE TEST FAILED: timeout (did a script error abort the run?)")
		quit(1)
		return true
	if _ran:
		return false
	_ran = true
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var beacon: Node = main.get_node("Island/Lighthouse/Beacon")
	var stations := main.get_node("Island/Details/Stations")
	var generator := stations.get_node("Station_Generator")

	# Clock starts at 17:30 and the pad/jump actions exist.
	_check(state.clock_text() == "17:30", "night starts at 17:30")
	for action in ["jump", "look_left", "look_up", "pause", "flashlight"]:
		_check(InputMap.has_action(action), "input action %s exists" % action)
	var pad := false
	for event in InputMap.action_get_events("interact"):
		pad = pad or event is InputEventJoypadButton
	_check(pad, "interact is mapped to a gamepad button")

	# Chest: gives the starter kit and moves the objective on.
	_check(state.objective().contains("baú"), "first objective points at the chest")
	main.get_node("Island/Details/Chest")._on_open(null)
	_check(state.has_flashlight and state.oil_cans == 1 and state.fuel_cans == 1, "chest gives flashlight, oil and fuel")
	_check(state.has_radio, "chest gives the portable radio")
	_check(state.objective().contains("livro"), "objective moves on to the logbook")

	_test_lamp(state, main, beacon)

	# Generator: wrong order resets, right order with fuel starts it.
	var wrong: int = (generator.order[0] + 1) % 4
	generator.get_node("Valve%s" % generator.LABELS[wrong]).interact(null)
	for index in generator.order:
		generator.get_node("Valve%s" % generator.LABELS[index]).interact(null)
	_check(not generator.running, "generator needs fuel even with the right order")
	state.fuel_cans = 1
	generator.get_node("FuelIn").interact(null)
	for index in generator.order:
		generator.get_node("Valve%s" % generator.LABELS[index]).interact(null)
	_check(generator.running and state.generator_on, "generator starts with fuel and the right order")

	# Breakers through their panel: capacity is two circuits.
	var fuses := stations.get_node("Station_Fuses")
	_check(fuses.find_children("*", "Area3D", true, false).size() == 1, "breaker box has a single panel interactable")
	var player: Node = main.get_node("Player")
	fuses._on_interacted(player)
	var panel: Node = fuses._console
	_check(panel != null and panel.is_open() and state.panel_open and player.locked, "the breaker panel opens, locks the player and flags panel_open")
	_check(not main.get_node("Hud/Root").visible, "the HUD hides while a panel is open")
	panel.press(0)
	panel.press(1)
	panel.press(2)
	_check(state.powered("radio") and state.powered("house") and not state.powered("motor"), "third breaker overloads")
	_check(panel._overload > 0.0, "the panel flags the overload")
	panel.press(0)
	panel.press(2)
	_check(not state.breakers["radio"] and state.powered("house") and state.powered("motor"), "freeing a slot lets another circuit on")
	_check(fuses._switch.prompt.contains("2/2"), "the box prompt shows the load")
	panel.close()
	_check(not state.panel_open and not player.locked and main.get_node("Hud/Root").visible, "closing the panel brings the HUD back")

	# Cellar: dials spell 8-3-5.
	var lock := stations.get_node("Station_Cellar")
	var cans_before: int = state.oil_cans
	for i in 3:
		for _n in lock.CODE[i]:
			lock.get_node("Dial%d" % i).interact(null)
	_check(state.oil_cans == cans_before + 2, "cellar opens with the code")

	_test_inventory(state, main)
	_test_radio(state, main, stations)
	_test_save(state, main)
	_test_cutscene(state, main)
	_test_status(state, main)

	print("PUZZLE TEST FAILED (%d)" % _failures if _failures else "PUZZLE TEST PASSED")
	quit(1 if _failures else 0)
	return true


## Lamp console (GDD 4.1.1): cold start, drowning, pressure limits, ratchet and night scaling.
func _test_lamp(state: Node, main: Node, beacon: Node) -> void:
	state.toast.connect(func(text: String) -> void: _last_toast = text)
	beacon.set_process(false)

	# One Interactable, the console; the old invisible stations are gone.
	var interactables := beacon.find_children("*", "Area3D", true, false)
	_check(interactables.size() == 1 and interactables[0].prompt == "Console da lâmpada", "lamp has a single console interactable")
	for old_name in ["OilTank", "Crank", "Lens"]:
		_check(beacon.find_child(old_name, true, false) == null, "station %s removed" % old_name)

	# The console opens over the running world and locks the keeper.
	var player: Node = main.get_node("Player")
	beacon._on_interacted(player)
	var console: Node = beacon._console
	_check(console != null and console.is_open() and player.locked, "interacting opens the console and locks the player")
	console.close()
	_check(not console.is_open() and not player.locked, "closing the console frees the player")

	# ABASTECER without a can does nothing but warn.
	state.oil_cans = 0
	console.press(0)
	_check(beacon.oil == 0.0 and _last_toast.contains("Sem óleo"), "refuel without a can only says Sem óleo")
	state.oil_cans = 2
	_check(beacon.refuel() and is_equal_approx(beacon.oil, 50.0) and state.oil_cans == 1, "a can adds 50 oil")

	# Drown: pump to 60, heat only to 50, open.
	_pump_to(beacon, 60.0)
	_heat_to(beacon, 50.0)
	var dirt_before: float = beacon.dirt
	var pressure_before: float = beacon.pressure
	beacon.toggle_valve()
	_check(not beacon.lit and beacon.temp == 0.0, "opening cold drowns the burner")
	_check(is_equal_approx(beacon.dirt, dirt_before + 25.0), "drowning soots the lens +25")
	_check(is_equal_approx(beacon.pressure, pressure_before - 20.0), "drowning drops pressure 20")
	_check(is_equal_approx(beacon.valve_lock, 8.0), "drowning jams the valve for 8 s")
	_pump_to(beacon, 60.0)
	_heat_to(beacon, 75.0)
	beacon.toggle_valve()
	_check(not beacon.lit, "the valve stays jammed while locked")
	_step(beacon, 8.5)

	# Pressure under the green: pfft, no flame, -2 oil.
	beacon.pressure = 35.0
	_heat_to(beacon, 75.0)
	var oil_before: float = beacon.oil
	beacon.toggle_valve()
	_check(not beacon.lit and is_equal_approx(beacon.oil, oil_before - 2.0), "low pressure: pfft without flame, -2 oil")

	# Cold start done right: pump to 60, heat to 70, open.
	_pump_to(beacon, 60.0)
	_heat_to(beacon, 70.0)
	beacon.toggle_valve()
	_check(beacon.lit and beacon.valve_open and state.lamp_lit and state.lamp_lit_once, "pump, heat, open lights the lamp")
	oil_before = beacon.oil
	_step(beacon, 5.0)
	_check(beacon.lit and beacon.oil < oil_before and absf(beacon.temp - 80.0) < 0.01, "lit: burns oil and holds the vaporiser at 80")

	# Pressure under 25 puts the flame out; pumping back while hot relights it.
	beacon.pressure = 25.5
	_step(beacon, 3.0)
	_check(not beacon.lit and beacon.valve_open and not state.lamp_lit, "pressure under 25 puts the flame out")
	_pump_to(beacon, 50.0)
	_check(beacon.lit, "pumping back while still hot relights without reheating")
	beacon.pressure = 20.0
	_step(beacon, 4.0)
	_check(not beacon.lit and not beacon.valve_open, "once the burner cools the valve closes")

	# Overpressure: ignition flares (+15 dirt); over 90 the safety valve dumps to 70.
	beacon.temp = 80.0
	beacon.pressure = 80.0
	dirt_before = beacon.dirt
	beacon.toggle_valve()
	_check(beacon.lit and is_equal_approx(beacon.dirt, dirt_before + 15.0), "opening over the green flares and soots +15")
	beacon.pressure = 88.0
	beacon._pump_wait = 0.0
	beacon.pump()
	_check(is_equal_approx(beacon.pressure, 70.0), "safety valve dumps to 70 above 90")
	beacon.pressure = 60.0

	# Ratchet: on the pulse +10, off +3, three misses in a row slip -20.
	beacon.wound = 50.0
	beacon._beat_time = 0.0
	_check(is_equal_approx(beacon.wind(), 10.0), "winding on the pulse adds 10")
	var half: float = beacon.beat_period() * 0.5
	beacon._beat_time = half
	_check(is_equal_approx(beacon.wind(), 3.0), "winding off the pulse adds 3")
	beacon._beat_time = half
	beacon.wind()
	beacon._beat_time = half
	beacon.wind()
	_check(is_equal_approx(beacon.wound, 49.0), "three misses in a row slip the ratchet -20")
	var head: Node3D = beacon.get_node("Head")
	var turned: float = head.rotation.y
	_step(beacon, 0.5)
	_check(not is_equal_approx(head.rotation.y, turned), "the head turns while wound")
	beacon.wound = 0.0
	turned = head.rotation.y
	_step(beacon, 1.0)
	_check(is_equal_approx(head.rotation.y, turned) and not state.lamp_working, "spring at 0: the head stops and the light counts as failing")
	beacon.wound = 80.0
	beacon.dirt = 90.0
	_step(beacon, 0.1)
	_check(not state.lamp_working, "reach under 40 % counts as failing")
	beacon.clean()
	_step(beacon, 0.1)
	_check(beacon.dirt < 1.0 and state.lamp_working, "a clean lens brings the light back")

	# Night scaling: at dawn the green band is 50-68 and the pulse 0.55 s; gusts from p >= 0.5.
	var start_minutes: float = state.minutes
	state.minutes = state.END_MINUTES
	_check(is_equal_approx(beacon.green_low(), 50.0) and is_equal_approx(beacon.green_high(), 68.0), "p = 1 narrows the green to 50-68")
	_check(is_equal_approx(beacon.beat_period(), 0.55), "p = 1 speeds the pulse to 0.55 s")
	state.minutes = state.START_MINUTES + (state.END_MINUTES - state.START_MINUTES) * 0.4
	var gusts: int = beacon.gusts
	_step(beacon, 100.0)
	_check(beacon.gusts == gusts, "no gusts before p = 0.5")
	state.minutes = state.START_MINUTES + (state.END_MINUTES - state.START_MINUTES) * 0.6
	_step(beacon, 100.0)
	_check(beacon.gusts > gusts, "gusts hit from p = 0.5")
	state.minutes = start_minutes
	beacon.set_process(true)


## Minecraft-style inventory: stacks, move, merge, split, swap, use, drop and pick back up.
func _test_inventory(state: Node, main: Node) -> void:
	var inv = state.inventory
	var panel: Node = main.get_node("Overlay")._inventory
	panel.open(main.get_node("Player"))
	_check(panel.is_open() and state.panel_open and not main.get_node("Hud/Root").visible, "Tab panel opens over the running night and hides the HUD")
	var minutes_before: float = state.minutes
	inv.clear()
	inv.add("oil", 5)
	_check(inv.slots[0] == {"id": "oil", "count": 4} and inv.slots[1] == {"id": "oil", "count": 1}, "5 oil cans take 2 slots (4 + 1)")
	inv.left(0)
	_check(inv.slots[0].is_empty() and inv.cursor == {"id": "oil", "count": 4}, "left click picks up the whole stack")
	inv.left(10)
	_check(inv.slots[10] == {"id": "oil", "count": 4} and inv.cursor.is_empty(), "left click on an empty slot puts it down")
	inv.left(1)
	inv.left(10)
	_check(inv.slots[10].count == 4 and inv.cursor.count == 1, "merging stops at the stack limit")
	inv.left(0)
	panel.right(10)
	_check(inv.cursor.count == 2 and inv.slots[10].count == 2, "right click takes half the stack")
	panel.left(0)
	_check(inv.slots[0].count == 3 and inv.cursor.is_empty(), "left click merges a held stack")
	inv.right(10)
	inv.right(20)
	_check(inv.slots[20] == {"id": "oil", "count": 1} and inv.slots[10].count == 1 and inv.cursor.is_empty(), "right click while holding places one")
	inv.add("water", 1)
	inv.left(1)
	inv.left(0)
	_check(inv.slots[0].id == "water" and inv.cursor == {"id": "oil", "count": 3}, "left click on another item swaps")
	inv.left(1)
	_check(state.oil_cans == 5 and state.inventory.count("water") == 1, "derived counts follow the slots")

	state.thirst = 40.0
	panel.use_slot(0)
	_check(is_equal_approx(state.thirst, 40.0), "drinking takes time")
	panel.tick_use(2.1)
	_check(is_equal_approx(state.thirst, 75.0) and inv.count("water") == 0, "a bottle gives thirst +35 and is spent")

	var pickups_before := get_nodes_in_group("pickups").size()
	panel.drop(1)
	var dropped := get_nodes_in_group("pickups")
	_check(dropped.size() == pickups_before + 1 and state.oil_cans == 4, "Q drops one item as a pickup on the ground")
	var pickup: Node = dropped[dropped.size() - 1]
	_check(pickup.item == "oil" and pickup.get_node("Take").prompt.begins_with("Pegar"), "the pickup says Pegar")
	pickup.collect()
	_check(state.oil_cans == 5 and pickup.is_queued_for_deletion(), "collecting gives the item back")

	inv.left(1)
	panel.close()
	_check(not state.panel_open and inv.cursor.is_empty() and state.oil_cans == 5, "closing stows the held stack")
	inv.add("biscuit", 5 * 32)
	var full_drop: Node = state.drop_item("bandage", 1, Vector3(0, 0, 40))
	full_drop.collect()
	_check(not full_drop.is_queued_for_deletion() and inv.count("bandage") == 0, "a full inventory leaves the item on the ground")
	full_drop.queue_free()
	_check(state.minutes >= minutes_before, "the clock is not paused by the inventory")
	inv.clear()
	state.oil_cans = 1
	state.fuel_cans = 1
	state.has_flashlight = true
	inv.add("radio", 1)


## Portable radio: signal by distance, answer once for +30 s, no carrier, battery.
func _test_radio(state: Node, main: Node, stations: Node) -> void:
	var radio := stations.get_node("Station_Radio")
	var panel: Node = main.get_node("Overlay")._radio
	var player: Node3D = main.get_node("Player")
	_check(main.get_node_or_null("Calls") == null, "the old calls panel is gone from the HUD")
	_check(not panel.ACTIONS.has("AUTORIZAR"), "the portable cannot authorise a docking")
	if state.breakers["house"]:
		state.toggle_breaker("house")
	if not state.breakers["radio"]:
		state.toggle_breaker("radio")
	var spawn: Vector3 = player.global_position
	var desk: Vector3 = radio.global_position
	radio._spawn_call()
	player.global_position = desk + Vector3(10, 0, 0)
	_check(panel.signal_loss() == 0.0, "10 m from the desk the signal is clean")
	player.global_position = desk + Vector3(30, 0, 0)
	var loss: float = panel.signal_loss()
	_check(loss >= 0.3 and loss <= 0.6 and panel.garble("Estrela do Norte", loss, 2).contains("#"), "30 m away letters turn into #")
	player.global_position = desk + Vector3(50, 0, 0)
	_check(panel.screen_text().contains("CHAMADA ENTRANDO"), "beyond 40 m only CHAMADA ENTRANDO shows")
	player.global_position = Vector3(0, 16.5, -12)
	_check(panel.signal_loss() == 0.0, "the top of the lighthouse counts as clean")
	player.global_position = desk + Vector3(5, 0, 0)
	var left: float = state.active_call.left
	radio.answer_remote()
	_check(is_equal_approx(state.active_call.left, left + 30.0) and state.active_call.status == "contact", "ATENDER makes contact and adds 30 s")
	radio.answer_remote()
	_check(is_equal_approx(state.active_call.left, left + 30.0), "the extension only happens once per call")
	state.toggle_breaker("radio")
	_check(panel.screen_text().contains("SEM PORTADORA"), "radio breaker off: SEM PORTADORA")
	state.toggle_breaker("radio")
	radio._end_call()

	state.radio_battery = 50.0
	state.radio_open = true
	state._tick_radio(2.0)
	_check(is_equal_approx(state.radio_battery, 49.0), "the battery drains 0.5/s with the screen open")
	state.radio_open = false
	radio._on_base(null)
	_check(state.radio_docked and not state.has_radio, "the portable sits in its base out of the inventory")
	state._tick_radio(5.0)
	_check(is_equal_approx(state.radio_battery, 59.0), "the base charges +2/s")
	radio._on_base(null)
	_check(not state.radio_docked and state.has_radio, "taking it back returns it to the inventory")
	player.global_position = spawn


## Save slots: everything in GameState, the keeper, saveable nodes and ground pickups round-trip.
func _test_save(state: Node, main: Node) -> void:
	var save: GDScript = load("res://save_game.gd")
	var slot := 97 # never one of the player's slots (1-3)
	save.delete(slot)
	var inv = state.inventory
	var player: Node3D = main.get_node("Player")
	var beacon: Node = main.get_node("Island/Lighthouse/Beacon")
	var start_minutes: float = state.minutes
	inv.clear()
	inv.add("oil", 3)
	inv.add("water", 2)
	inv.left(0)
	inv.left(7)
	state.thirst = 33.5
	state.hunger = 44.0
	state.health = 77.0
	state.minutes = state.START_MINUTES + 125.0
	state.ships_saved = 2
	state.radio_battery = 61.0
	state.add_note("Nota de teste")
	beacon.wound = 42.0
	player.global_position = Vector3(5, 1, 30)
	player.rotation.y = 1.25
	state.drop_item("biscuit", 2, Vector3(3, 0, 30))
	save.write(slot, main)
	_check(save.exists(slot) and save.meta(slot).clock == "19:35", "a save writes the slot with its night time")

	inv.clear()
	state.thirst = 90.0
	state.minutes = state.START_MINUTES
	state.ships_saved = 0
	beacon.wound = 0.0
	player.global_position = Vector3.ZERO
	save.apply(save.read(slot), main)
	_check(inv.slots[7] == {"id": "oil", "count": 3} and inv.slots[1] == {"id": "water", "count": 2}, "inventory slots round-trip in place")
	_check(is_equal_approx(state.thirst, 33.5) and is_equal_approx(state.health, 77.0) and state.clock_text() == "19:35", "status and clock round-trip")
	_check(state.ships_saved == 2 and is_equal_approx(state.radio_battery, 61.0) and state.notes.has("Nota de teste"), "ships, battery and notes round-trip")
	_check(is_equal_approx(beacon.wound, 42.0), "the lamp state round-trips")
	_check(player.global_position.distance_to(Vector3(5, 1, 30)) < 0.01 and is_equal_approx(player.rotation.y, 1.25), "the keeper's position and facing round-trip")
	var dropped := get_nodes_in_group("pickups").filter(func(p: Node) -> bool: return p.item == "biscuit" and p.global_position.distance_to(Vector3(3, 0, 30)) < 0.01)
	_check(dropped.size() == 1 and dropped[0].count == 2, "pickups on the ground round-trip")
	save.delete(slot)
	_check(not save.exists(slot), "a slot can be deleted")
	state.minutes = start_minutes
	player.global_position = Vector3(0.4, 0.05, 49.8)


## The opening cutscene freezes the clock; skipping lands on the pier at 17:30 with control.
func _test_cutscene(state: Node, main: Node) -> void:
	var player: Node3D = main.get_node("Player")
	state.minutes = state.START_MINUTES
	state.in_game = false
	var ended := [false]
	var cutscene: Node = load("res://ui/opening_cutscene.gd").new()
	cutscene.finished.connect(func() -> void: ended[0] = true)
	main.add_child(cutscene)
	_check(state.panel_open and player.locked and not state.in_game, "the cutscene hides the HUD and locks the keeper")
	cutscene.advance(20.0)
	_check(state.clock_text() == "17:30" and not state.in_game, "the clock does not run during the cutscene")
	cutscene.skip()
	cutscene.advance(0.6)
	cutscene.advance(3.5)
	_check(ended[0], "skipping jumps to the last shot and ends")
	state.begin_play()
	var chest := Vector3(-0.7, 0.6, 47.2)
	_check(player.global_position.distance_to(chest) < 3.5 and not player.locked, "after the cutscene the keeper stands on the pier next to the chest")
	_check(state.in_game and state.clock_text() == "17:30" and not state.panel_open, "control starts at 17:30")
	_check(player.get_viewport().get_camera_3d() == player.get_node("Head/Camera3D"), "the keeper's camera is back")


## Thirst, hunger and health rates, thresholds, damage and death with its cause.
func _test_status(state: Node, main: Node) -> void:
	var hour: float = 60.0 * state.SECONDS_PER_MINUTE
	state.thirst = 80.0
	state.hunger = 60.0
	state.health = 100.0
	state.sprinting = false
	state.in_water = false
	state.tick_status(hour)
	_check(is_equal_approx(state.thirst, 72.0) and is_equal_approx(state.hunger, 55.0), "one hour: thirst -8, hunger -5")
	state.sprinting = true
	state.tick_status(hour)
	_check(is_equal_approx(state.thirst, 60.0), "sprinting drinks 1.5x faster")
	state.sprinting = false
	state.thirst = 80.0
	for i in 99:
		state.tick_status(hour / 10.0)
	_check(state.thirst > 0.0, "thirst still above 0 before 10 h")
	state.tick_status(hour / 10.0 + 0.01)
	_check(state.thirst == 0.0, "thirst empties after 10 h (17:30 -> 03:30)")
	state.hunger = 60.0
	state.health = 100.0
	state.tick_status(state.SECONDS_PER_MINUTE)
	_check(is_equal_approx(state.health, 99.0) and not state.can_sprint(), "thirst at 0: -1 health per minute and no sprint")
	_check(state.critical()["thirst"] and not state.critical()["hunger"], "critical icon only below the line")
	state.thirst = 60.0
	state.in_water = true
	var health: float = state.health
	state.tick_status(1.0)
	_check(state.health <= health - 2.9, "the sea takes 3 health per second")
	_check(state.cold_left > 0.0, "a soaking leaves the keeper cold")
	state.in_water = false
	state.health = 60.0
	state.tick_status(state.SECONDS_PER_MINUTE * 5.0)
	_check(state.health > 60.0 and state.health <= 70.0, "health regenerates up to 70 when fed")
	state.health = 10.0
	state.damage(60.0, "A queda")
	_check(state.dead and state.death_cause == "A queda", "health 0 kills with a cause")
	_check(main.get_node("Overlay")._ending.visible and main.get_node("Overlay")._ending_text.text.contains("A queda"), "the summary shows the cause of death")
	paused = false


func _step(beacon: Node, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		beacon.simulate(0.05)
		t += 0.05


func _pump_to(beacon: Node, target: float) -> void:
	while beacon.pressure < target:
		beacon.pump()
		beacon.simulate(0.26)


func _heat_to(beacon: Node, target: float) -> void:
	while beacon.temp < target:
		beacon.heat(0.05)
		beacon.simulate(0.05)


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + message)
