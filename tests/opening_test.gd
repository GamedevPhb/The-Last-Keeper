extends SceneTree
## Headless test: a new game starts the opening cutscene; loading a save does not.
## Run: godot-4 --headless --path . --script res://tests/opening_test.gd

var _failures := 0
var _step := 0
var _frames := 0
var _main: Node
var _state: Node


func _process(_delta: float) -> bool:
	_state = root.get_node("GameState")
	_frames += 1
	match _step:
		0:
			_state.reset()
			_state.pending_load = {}
			_state.play_intro = true
			_main = load("res://main.tscn").instantiate()
			root.add_child(_main)
			_step = 1
			_frames = 0
		1:
			if _frames < 3:
				return false
			var cut := _find_cutscene()
			_check(cut != null, "new game spawns the opening cutscene")
			_check(not _state.in_game, "clock stopped during the opening")
			_check(not _state.play_intro, "play_intro consumed")
			if cut:
				var player: Node = _main.get_node("Player")
				_check(player.locked, "player locked during the opening")
				_check(cut.get("_camera").current, "cutscene camera is current")
				for i in 400:
					cut.advance(0.25)
				_check(_find_cutscene() == null or _find_cutscene().is_queued_for_deletion(), "cutscene finishes")
				_check(_state.in_game, "clock starts after the opening")
				_check(not player.locked, "player free after the opening")
				_check(absf(player.global_position.z - 49.8) < 0.5, "player on the pier")
				_check(is_equal_approx(_state.minutes, float(_state.START_MINUTES)), "starts at 17:30")
			_main.queue_free()
			_step = 2
			_frames = 0
		2:
			if _frames < 3:
				return false
			_state.reset()
			_state.pending_load = {"slot": 1, "minutes": 1200.0}
			_state.play_intro = false
			_main = load("res://main.tscn").instantiate()
			root.add_child(_main)
			_step = 3
			_frames = 0
		3:
			if _frames < 3:
				return false
			_check(_find_cutscene() == null, "loading a save does not play the opening")
			if _failures > 0:
				printerr("OPENING TEST FAILED: %d failure(s)" % _failures)
				quit(1)
			else:
				print("OPENING TEST PASSED")
				quit(0)
			return true
	return false


func _find_cutscene() -> Node:
	for child in _main.get_children():
		if child.get_script() and str(child.get_script().resource_path).ends_with("opening_cutscene.gd"):
			return child
	return null


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: " + what)
