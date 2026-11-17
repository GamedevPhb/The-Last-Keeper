extends SceneTree
## Headless test of the story scenes: each trigger fires once, the clock waits while a scene
## plays, skipping works, and the seen flags survive a save. Run:
## godot-4 --headless --path . --script res://tests/scenes_test.gd

var _failures := 0
var _frames := 0
var _stage := 0
var _state: Node
var _main: Node
var _asked: Array[String] = []


func _initialize() -> void:
	_main = load("res://main.tscn").instantiate()
	root.add_child(_main)


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 3:
		return false
	_state = root.get_node("GameState")
	if _stage == 0:
		_stage = 1
		_state.scene_requested.connect(func(id: String) -> void: _asked.append(id))
		_state.begin_play()
		var player: Node = _main.get_node("Player")
		player.global_position = Vector3(27.0, 0.5, 7.0) # inside the house
		return false
	if _stage == 1:
		# The house scene fires after the player stays in (physics frames: drive the check directly).
		_state._check_scenes(1.0)
		_check(_asked == ["house"], "entering the house asks for the house scene")
		_state._check_scenes(1.0)
		_check(_asked.size() == 1, "a scene fires only once")
		_play_through("house")
		var player: Node = _main.get_node("Player")
		player.global_position = Vector3(0.0, 0.5, 49.0)
		# Clock scenes.
		_state.minutes = 23.0 * 60.0 + 46.0
		_state._check_scenes(0.1)
		_check(_asked.back() == "bell", "23:45 asks for the Sineiro scene")
		_play_through("bell")
		_state.minutes = 24.0 * 60.0 + 1.0
		_state._check_scenes(0.1)
		_check(_asked.back() == "lavado", "00:00 asks for the first Lavado")
		_play_through("lavado")
		_state.minutes = 27.0 * 60.0 + 6.0
		_state._check_scenes(0.1)
		_check(_asked.back() == "captain", "03:05 asks for the Captain")
		_play_through("captain")
		_state.lamp_lit_once = true
		_state._check_scenes(2.0)
		_check(_asked.back() == "lamp", "the first lit lamp asks for its scene")
		_play_through("lamp")
		# Saved flags and a skipped scene.
		var saved: Dictionary = _state.to_save()
		_state.scenes_seen = {}
		_state.from_save(saved)
		_check(_state.scenes_seen.get("house", false) and _state.scenes_seen.get("captain", false), "seen scenes survive a save")
		_state.minutes = 27.0 * 60.0 + 30.0
		_state.scenes_seen = {"house": true, "lamp": true, "bell": true, "lavado": true}
		_state._check_scenes(0.1)
		_check(_asked.size() == 5 and _state.scenes_seen.get("captain", false), "a scene missed by 10+ minutes is dropped")
		# The Aurora scene: only the lying Aurora, once.
		_asked.clear()
		_state.scene_active = false
		_state.ship_event.emit("Marlin", "liar")
		_state.ship_event.emit("Aurora", "docked")
		_state.ship_event.emit("Aurora", "liar")
		_state.ship_event.emit("Aurora", "liar")
		_stage = 2
		_frames = 0
		return false
	if _stage == 2:
		if _frames < 2:
			return false
		_check(_asked == ["aurora"], "only the lying Aurora asks for its scene, once (got %s)" % [_asked])
		_check(_state.scenes_seen.get("aurora", false), "the Aurora scene is saved as seen")
		var scene := _find("aurora")
		_check(scene != null, "the Aurora scene plays")
		if scene:
			var message := false
			var length := 0.0
			while length < 60.0 and not scene.is_queued_for_deletion():
				scene.advance(0.25)
				length += 0.25
				message = message or scene._alert.visible and scene._alert.text.begins_with("VOCÊ NÃO DEVERIA TER AUTORIZADO")
			_check(message, "the red message shows")
			_check(not AudioServer.is_bus_mute(0), "sound is back after the scare")
			_check(length < 30.0, "the Aurora scene is short")
		if _failures > 0:
			printerr("SCENES TEST FAILED: %d checks" % _failures)
			quit(1)
		else:
			print("SCENES TEST PASSED")
			quit(0)
		return true
	return false


## Plays the scene that was just requested to its end (or skips it), checking the clock stops.
func _play_through(id: String) -> void:
	# The overlay already spawned it from the scene_requested signal.
	var scene := _find(id)
	_check(scene != null, "scene %s spawned" % id)
	if scene == null:
		return
	_check(_state.scene_active, "clock waits during %s" % id)
	var before: float = _state.minutes
	var length := 0.0
	var skip := id == "lamp"
	while length < 60.0 and not scene.is_queued_for_deletion():
		scene.advance(0.25)
		length += 0.25
		if skip and length > 1.0:
			scene.skip()
	_check(scene.is_queued_for_deletion(), "scene %s ends (%.0f s)" % [id, length])
	_check(length <= 30.0, "scene %s is short" % id)
	_check(not _state.scene_active, "clock resumes after %s" % id)
	_check(is_equal_approx(_state.minutes, before), "the night clock did not move during %s" % id)
	scene.free()


func _find(id: String) -> Node:
	for child in _main.get_children():
		if child.get_script() and "scene_id" in child and child.scene_id == id and not child.is_queued_for_deletion():
			return child
	return null


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)
