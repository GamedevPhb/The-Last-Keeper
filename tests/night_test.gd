extends SceneTree
## Headless test of night 1 balance, the Aurora scene through the real radio flow, the cellar code
## note, the dawn -> next night hand-over and the video options.
## Run: godot-4 --headless --path . --script res://tests/night_test.gd

var _frame := 0
var _failures := 0
var _main: Node
var _scene: Node


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)


func _process(_delta: float) -> bool:
	_frame += 1
	var state := root.get_node("GameState")
	if _frame == 1:
		state.reset()
		state.pending_load = {}
		state.play_intro = false
		_main = load("res://main.tscn").instantiate()
		root.add_child(_main)
	elif _frame == 4:
		state.begin_play()
		_balance(state)
		_code_note(state)
		_aurora_flow(state)
	elif _frame == 8:
		_check(state.scenes_seen.get("aurora", false), "Aurora scene marked after an honest authorization")
		_scene = _scene_node("aurora")
		_check(_scene != null and state.scene_active, "Aurora scene is playing")
		if _scene:
			for i in 40:
				_scene.advance(1.0)
		_check(not state.scene_active, "Aurora scene ends")
		_dawn(state)
	elif _frame == 12:
		_check(_scene_node("dawn") != null, "the dawn scene plays after Continuar")
		for link in _scene.finished.get_connections(): # the real handler reloads the scene; _next_night checks its parts
			_scene.finished.disconnect(link.callable)
		for i in 40:
			if is_instance_valid(_scene):
				_scene.advance(1.0)
		_check(not state.scene_active, "dawn scene ends")
		_next_night(state)
		_video()
		print("NIGHT TEST %s" % ("PASSED" if _failures == 0 else "FAILED (%d)" % _failures))
		quit(0 if _failures == 0 else 1)
	return false


func _scene_node(id: String) -> Node:
	for child in _main.get_children():
		if child.get("scene_id") == id:
			return child
	return null


func _balance(state: Node) -> void:
	_check(state.night == 1 and state.tutorial(), "starts on night 1")
	_check(is_equal_approx(state.night_factor(), 0.55), "night 1 factor 0.55")
	state.night = 2
	_check(is_equal_approx(state.night_factor(), 1.0), "night 2 factor 1.0")
	state.night = 4
	_check(state.night_factor() > 1.2, "night 4 grows")
	state.night = 1
	state.flashlight_on = true
	state.flashlight_battery = 100.0
	state._tick_flashlight(10.0)
	var night_one: float = 100.0 - state.flashlight_battery
	state.night = 2
	state.flashlight_battery = 100.0
	state._tick_flashlight(10.0)
	_check(is_equal_approx(night_one * 2.0, 100.0 - state.flashlight_battery), "night 1 flashlight lasts twice as long")
	state.night = 1
	state.flashlight_on = false
	state.flashlight_battery = 100.0
	var beacon := _main.get_node("Island/Lighthouse/Beacon")
	beacon.lit = true
	beacon.pressure = 60.0
	beacon.simulate(10.0)
	var lost_one: float = 60.0 - beacon.pressure
	beacon.pressure = 60.0
	state.night = 2
	beacon.simulate(10.0)
	_check(lost_one < 60.0 - beacon.pressure, "night 1 leaks less pressure")
	beacon.lit = false
	state.night = 1
	for node in _main.find_children("*", "Node3D", true, false):
		var script := node.get_script() as Script
		if script and script.resource_path.ends_with("invasion.gd"):
			_check(node.waves() == [3, 4, 5], "night 1 invasion is 3-4-5")
			state.night = 2
			_check(node.waves() == [4, 6, 8], "night 2 invasion is 4-6-8")
			state.night = 1
	state.give("oil", 1)
	state.chest_opened = true
	_check(state.objective().contains("livro"), "tutorial: book comes after the chest")
	state.book_read = true
	state.generator_started = true
	state.breakers["radio"] = true
	_check(state.objective().contains("NO VERDE"), "lamp hint spells out the green zone")
	state.lamp_lit_once = true
	_check(state.objective().contains("rádio"), "tutorial points at the first call")
	var radio := _radio()
	_check(radio._anomaly_every() == 0, "no liars before midnight on night 1")
	state.minutes = 24.0 * 60.0 + 5.0
	_check(radio._anomaly_every() == 3, "liars every third call after midnight on night 1")
	state.minutes = 17.5 * 60.0 + 0.0


func _code_note(state: Node) -> void:
	state.notes.clear()
	state.add_note("Inscrição: OITO vigias descansam aqui. O nono ainda vigia.")
	state.add_note("Etiqueta do caixote: LOTE 3, ÓLEO DE LAMPARINA.")
	_check(not state.notes.has(state.CODE_NOTE), "no code note with two clues")
	state.add_note("Placa do tanque: CAPACIDADE 5 LATAS.")
	_check(state.notes.has(state.CODE_NOTE), "code note after the third clue")


func _radio() -> Node:
	return get_first_node_in_group("radio_desk")


## The real path: the Authorize interactable of the desk resolves a call from the Aurora.
func _aurora_flow(state: Node) -> void:
	var radio := _radio()
	state.generator_on = true
	state.breakers["radio"] = true
	state.lamp_lit = true
	state.lamp_working = true
	radio._call = {"call": "Aurora", "register": "carvão", "claim": "carvão", "freq": 0, "status": "contact", "left": 30.0, "total": 30.0,
		"answered": true, "extended": false, "bearing": "N", "seed": 1}
	radio._contact = true
	state.active_call = radio._call
	radio._authorize.interacted.emit(null)
	_check(state.ships_saved == 1, "Aurora authorization counted")


func _dawn(state: Node) -> void:
	state.finished = true
	state.minutes = state.END_MINUTES
	state.ships_saved = 3
	state.add_note("nota de teste")
	state.give("battery", 1)
	var overlay: Node = _main.get_node("Overlay")
	overlay._show_ending()
	_check(overlay._ending.visible, "dawn summary opens")
	overlay._continue_night()
	_scene = _scene_node("dawn")


func _next_night(state: Node) -> void:
	var overlay: Node = _main.get_node("Overlay")
	var batteries: int = state.inventory.count("battery")
	state.save_slot = 0
	var data: Dictionary = overlay._advance_and_save()
	_check(state.night == 2 and not state.tutorial(), "night 2 after Continuar")
	_check(state.minutes == state.START_MINUTES and not state.finished, "clock back to 17:30")
	_check(state.ships_saved == 0 and not state.generator_on and not state.lamp_lit, "stations reset")
	_check(state.inventory.count("battery") == batteries, "bag kept")
	_check(state.notes.has("nota de teste") and state.book_read, "notes and book kept")
	_check(int(data.state.night) == 2, "save data carries the night")
	state.night = 1
	state.from_save(data.state)
	_check(state.night == 2, "night restored from save")


func _video() -> void:
	var settings := root.get_node("Settings")
	_check(settings.view_size(0) == Vector2i(320, 240), "4:3 view is 320x240")
	_check(settings.view_size(1) == Vector2i(427, 240), "16:9 view is 427x240")
	_check(settings.view_size(3) == Vector2i(560, 240), "21:9 view is 560x240")
	_check(settings.view_size(4) == Vector2i(320, 240), "native keeps the 320x240 base")
	_check(settings.parse_resolution("1280x720") == Vector2i(1280, 720), "resolution parses")
	_check(settings.parse_resolution("lixo") == Vector2i(960, 720), "bad resolution falls back")
	var screen := DisplayServer.screen_get_size()
	_check(screen == Vector2i.ZERO or settings.resolutions().has(screen), "monitor size is in the list")
