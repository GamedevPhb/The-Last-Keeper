extends SceneTree
## Headless test of the Portinho easter egg: trigger, sweeps, solution, crate, doll, save, night 2.
## Run: godot-4 --headless --path . --script res://tests/portinho_test.gd

var _failures := 0
var _frames := 0
var _main: Node
var _state: Node
var _asked: Array[String] = []


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	_state = root.get_node("GameState")
	_state.scene_requested.connect(func(id: String) -> void: _asked.append(id))
	_state.begin_play()
	_state._panels.clear()
	_state.panel_open = false
	_state.chest_opened = true
	_state.book_read = true
	_state.generator_started = true
	_state.breakers["radio"] = true
	_state.lamp_lit_once = true
	for id: String in ["house", "lamp", "bell", "lavado", "captain"]:
		_state.scenes_seen[id] = true
	var giant: Node3D = get_first_node_in_group_of("portinho_giant")
	var crate: Node3D = get_first_node_in_group_of("supply_crate")
	_check(giant != null and crate != null, "giant and crate exist in the island")
	_check(not giant.visible, "giant hidden by default")

	# Trigger: 21:45 on night 1, once.
	_state.minutes = 21.0 * 60.0 + 30.0
	_state._check_scenes(0.1)
	_check(not _asked.has("portinho"), "no scene before 21:45")
	_state.minutes = 21.0 * 60.0 + 46.0
	_state._check_scenes(0.1)
	_check(_asked.has("portinho"), "21:45 asks for the Portinho scene")
	_state._check_scenes(0.1)
	_check(_asked.count("portinho") == 1, "the scene fires once")
	_check(_state.portinho_active(), "the giant is active after the scene")
	_check(_state.objective().contains("0/3"), "objective mentions the giant")
	giant.set_mood("wave")
	giant._process(0.1)
	_check(giant.visible, "giant visible once met")
	_check(giant.point().distance_to(Vector3(56, 13, -51)) < 3.0, "point() is near (56,13,-51)")

	# Dark lighthouse: one-time hint.
	var toasts: Array[String] = []
	_state.toast.connect(func(t: String) -> void: toasts.append(t))
	_state.panel_open = false # the opening cutscene may still hold it
	_state._portinho_tick()
	_check(toasts.has("Alguém acena no horizonte. Acenda o farol."), "dark lamp hint")
	_state._portinho_tick()
	_check(toasts.size() == 1, "hint only once")

	# Sweeps: reach short or lamp dead do not count.
	_check(not _state.portinho_sweep(true, false), "a short beam does not count")
	_check(toasts.has("A luz não chega lá."), "says the light does not reach")
	_state.portinho_sweep(true, false)
	_check(toasts.count("A luz não chega lá.") == 1, "reach message only once")
	_check(not _state.portinho_sweep(false, true), "a dead lamp does not count")
	_check(_state.portinho_sweeps == 0, "no sweeps yet")
	_state.portinho_sweep(true, true)
	_state.portinho_sweep(true, true)
	_check(_state.portinho_sweeps == 2 and not _state.portinho_solved, "two sweeps do not solve")

	# Save in the middle, load back.
	var mid: Dictionary = _state.to_save()
	_state.portinho_sweeps = 0
	_state.from_save(mid)
	_check(_state.portinho_sweeps == 2, "sweeps survive a save")

	_asked.clear()
	_state.portinho_sweep(true, true)
	_check(_state.portinho_solved, "three sweeps solve it")
	_check(_asked == ["portinho_friend"], "solving asks for the friend scene")
	_check(not _state.portinho_sweep(true, true), "no sweeps after solving")
	var doll: Node3D = get_first_node_in_group_of("portinho_doll_node")
	for node in _main.find_children("PortinhoDoll", "Node3D", true, false):
		doll = node
	doll._process(0.1)
	_check(doll.visible, "the doll shows after the friend scene")
	_check(_state.objective().find("gigante") == -1, "objective clears")

	# Giant stays 20 s after thumbs_up, then goes.
	giant.set_mood("thumbs_up")
	giant._process(0.1)
	_check(giant.visible, "giant lingers after thumbs_up")
	giant._process(21.0)
	_check(not giant.visible, "giant gone after ~20 s")

	# Crate: pickups once.
	var before := get_nodes_in_group("pickups").size()
	crate.appear()
	crate.appear()
	_check(get_nodes_in_group("pickups").size() == before + 4, "the crate gives 4 pickups once")
	_check(crate.get_child(0).visible, "the crate is visible")

	# Hints by context.
	_check(_state.portinho_context(Vector3(0, 1, -11)) == "lamp", "context: lamp")
	_check(_state.portinho_context(Vector3(-20, 1, 14)) == "generator", "context: generator")
	_check(_state.portinho_context(Vector3(28.2, 1, 5.0)) == "fuses", "context: fuses")
	_check(_state.portinho_context(Vector3(25.2, 1, 5.0)) == "radio", "context: radio")
	_check(_state.portinho_context(Vector3(7, 1, -54)) == "fishing", "context: fishing")
	_check(_state.portinho_context(Vector3(-67, 1, -19)) == "watchtower", "context: watchtower")
	_check(_state.portinho_context(Vector3(40, 1, 40)) == "idle", "context: idle far away")
	var lines: Array = _state.PORTINHO_HINTS.HINTS["lamp"]
	var last := ""
	var repeats := 0
	for i in 20:
		var line: String = _state.portinho_hint(Vector3(0, 1, -11))
		_check(line in lines, "hint line comes from the lamp list")
		if line == last:
			repeats += 1
		last = line
	_check(repeats == 0, "no repeated hint twice in a row")

	# Take the doll: item in the inventory, hint on use.
	doll._on_take(null)
	_check(_state.inventory.count("portinho") == 1 and _state.portinho_doll_taken, "doll goes to the inventory")
	_check(not doll.visible, "doll leaves the desk")

	# Persistence of solved + crate; night 2 without the giant.
	var done: Dictionary = _state.to_save()
	_state.portinho_solved = false
	_state.portinho_crate_given = false
	_state.from_save(done)
	_check(_state.portinho_solved and _state.portinho_crate_given and _state.portinho_doll_taken, "flags survive a save")
	_state.portinho_solved = false
	_state.advance_night()
	_check(not _state.portinho_active(), "night 2: no giant even if unsolved")
	_asked.clear()
	_state.minutes = 21.0 * 60.0 + 46.0
	_state.scenes_seen.erase("portinho")
	_state._check_scenes(0.1)
	_check(not _asked.has("portinho"), "night 2: the scene does not fire")
	_check(_state.scenes_seen.get("portinho_friend", false), "the friend scene stays seen across nights")
	_check(doll.visible == false, "doll stays taken")

	if _failures == 0:
		print("PORTINHO TEST: OK")
	quit(_failures)
	return true


func get_first_node_in_group_of(group: String) -> Node3D:
	return get_first_node_in_group(group) as Node3D
