extends SceneTree
## Plays one story scene in a real window for a visual check. Run:
## godot-4 --path . --script res://tests/preview_scene.gd -- aurora

var _frames := 0
var _id := "aurora"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_id = args[0]
	root.add_child(load("res://main.tscn").instantiate())


func _process(delta: float) -> bool:
	_frames += 1
	var state: Node = root.get_node("GameState")
	if _frames == 5:
		state.begin_play()
	elif _frames == 20:
		if _id == "aurora":
			state.ship_event.emit("Aurora", "liar")
		else:
			state.play_scene(_id)
	elif _frames > 20 and _frames > 60 * 45:
		quit()
	return false
