extends SceneTree
## Capture (not a test): the giant Portinho seen from the lamp room, cold and lit by the beam.
var _f := 0
var _cam: Camera3D
var _giant: Node3D
func _initialize() -> void:
	root.size = Vector2i(960, 720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.add_child(load("res://main.tscn").instantiate())
func _process(_d: float) -> bool:
	_f += 1
	var gs := root.get_node("GameState")
	if _f == 5:
		gs.begin_play()
	if _f == 15:
		gs.minutes = 22.0 * 60.0
		gs.scenes_seen["portinho"] = true
		var main := root.get_child(root.get_child_count() - 1)
		for n in ["Hud", "Overlay", "Player", "Hands"]:
			var x := main.find_child(n, true, false)
			if x is CanvasItem or x is CanvasLayer: x.visible = false
		var pl := main.find_child("Player", true, false)
		if pl: pl.process_mode = Node.PROCESS_MODE_DISABLED
		_giant = get_first_node_in_group("portinho_giant")
		_cam = Camera3D.new()
		_cam.far = 75.0
		root.add_child(_cam)
		_cam.make_current()
		_cam.position = Vector3(0, 17.5, -12)
		_cam.look_at(_giant.point() + Vector3(-8, -4, 0))
	if _f == 30:
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/shots/portinho_frio.png"))
		_giant._glow = 5.0
	if _f == 31:
		_giant._glow = 5.0
	if _f == 33:
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/shots/portinho_aceso.png"))
		quit()
		return true
	return false
