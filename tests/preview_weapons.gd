extends SceneTree
## Saves a screenshot of a weapon in hand for a visual check. Run (needs a window):
## godot-4 --path . --script res://tests/preview_weapons.gd -- shotgun
## Writes docs/shots/arma_<id>.png. Extra argument "fire" shoots before the capture.

var _frames := 0
var _id := "axe"
var _fire := false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_id = args[0]
	_fire = args.has("fire")
	root.add_child(load("res://main.tscn").instantiate())


func _process(_delta: float) -> bool:
	_frames += 1
	var state: Node = root.get_node("GameState")
	if _frames == 5:
		state.begin_play()
		state.give(_id, 1)
		state.give("ammo_pistol", 6)
		state.give("shells", 4)
		state.equip(_id)
		state.mags.pistol = 6
		state.mags.shotgun = 2
		state.flashlight_on = true
	elif _frames == 40 and _fire:
		root.get_node("Main/Player/Head/Camera3D/Weapons").cooldown = 0.0
		root.get_node("Main/Player/Head/Camera3D/Weapons").attack()
	elif _frames == (46 if _fire else 60):
		root.get_viewport().get_texture().get_image().save_png("res://docs/shots/arma_%s.png" % _id)
		quit()
	return false
