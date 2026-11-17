extends SceneTree
## Capturas ao nivel do chao (nao e teste): godot-4 --path . --script res://tests/_ground_shot.gd
const VIEWS := [
	["pier", Vector3(0.4, 1.7, 46.0), Vector3(0.4, 2.0, 30.0)],
	["enseada", Vector3(-12, 3, 40), Vector3(4, 0, 46)],
	["farol", Vector3(8, 1.7, 8), Vector3(0, 6, -12)],
	["gruta", Vector3(31, 1.7, -46), Vector3(33, 6, -68)],
	["mata", Vector3(-35, 1.7, -4), Vector3(-60, 3, -12)],
	["garganta", Vector3(0, 1.7, -22), Vector3(0, 3, -44)],
	["costa_norte", Vector3(-4, 1.7, -50), Vector3(8, 0, -60)],
]
var _f := 0
var _cam: Camera3D
func _initialize() -> void:
	root.size = Vector2i(960, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.add_child(load("res://main.tscn").instantiate())
func _process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		root.get_node("GameState").begin_play()
	if _f == 15:
		var main := root.get_child(root.get_child_count() - 1)
		for n in ["Hud", "Overlay", "Player", "Hands"]:
			var x := main.find_child(n, true, false)
			if x is CanvasItem or x is CanvasLayer: x.visible = false
		var pl := main.find_child("Player", true, false)
		if pl: pl.process_mode = Node.PROCESS_MODE_DISABLED
		_cam = Camera3D.new()
		_cam.far = 120.0
		root.add_child(_cam)
		_cam.make_current()
	if _f >= 20 and (_f - 20) % 6 == 0:
		var i := (_f - 20) / 6
		if i > 0:
			root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/shots/terreno_%s.png" % VIEWS[i - 1][0]))
		if i >= VIEWS.size():
			quit()
			return true
		_cam.position = VIEWS[i][1]
		_cam.look_at(VIEWS[i][2])
	return false
