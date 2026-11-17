extends SceneTree
var _f := 0
var _cam: Camera3D
func _initialize() -> void:
	root.size = Vector2i(1280, 1280)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.add_child(load("res://main.tscn").instantiate())
func _process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		root.get_node("GameState").begin_play()
	if _f == 15:
		var main := root.get_child(root.get_child_count() - 1)
		var we := main.find_child("WorldEnvironment", true, false)
		if we: we.environment.fog_enabled = false
		for n in ["PsxPost", "Hud", "Overlay", "Player", "Hands"]:
			var x := main.find_child(n, true, false)
			if x and x is CanvasItem: x.visible = false
			elif x and x is CanvasLayer: x.visible = false
		_cam = Camera3D.new()
		_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		_cam.size = 190.0
		_cam.far = 500.0
		_cam.rotation_degrees = Vector3(-90, 0, 0)
		_cam.position = Vector3(-8, 120, -6)
		root.add_child(_cam)
		_cam.make_current()
	if _f == 30:
		root.get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://docs/shots/mapa_expansao_godot.png"))
		quit()
	return false
