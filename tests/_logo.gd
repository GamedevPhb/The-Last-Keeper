extends SceneTree
const W := 480
const H := 200
var vp: SubViewport
var f := 0
func _initialize() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.035, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.3, 0.26)
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.06, 0.05)
	env.fog_density = 0.035
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.fov = 38
	cam.position = Vector3(0, 0.2, 10.5)
	vp.add_child(cam)
	cam.current = true
	var shader: Shader = load("res://shaders/psx_lit.gdshader")
	var bone := _mat(shader, Color(0.86, 0.82, 0.62))
	var stone := _mat(shader, Color(0.3, 0.32, 0.3))
	var font := FontFile.new()
	font.load_dynamic_font("/usr/share/fonts/opentype/urw-base35/NimbusRoman-Bold.otf")
	_text("THE LAST", font, 70, 0.9, Vector3(-0.3, 1.65, 0), bone)
	_text("KEEPER", font, 150, 1.5, Vector3(-0.3, -0.25, 0), bone)
	_text("FAROL 7", font, 60, 0.3, Vector3(-0.3, -1.95, 0), _mat(shader, Color(0.85, 0.2, 0.14)))
	# Lighthouse behind the title, right side
	var tower := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.55
	cyl.bottom_radius = 0.9
	cyl.height = 7.0
	cyl.radial_segments = 8
	tower.mesh = cyl
	tower.material_override = stone
	tower.position = Vector3(6.4, -0.5, -6.0)
	vp.add_child(tower)
	var lamp := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.5
	sph.height = 1.0
	sph.radial_segments = 8
	sph.rings = 4
	lamp.mesh = sph
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1, 0.85, 0.5)
	lamp.material_override = lm
	lamp.position = Vector3(6.4, 3.3, -6.0)
	vp.add_child(lamp)
	var beam := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.1
	cone.bottom_radius = 3.2
	cone.height = 14.0
	cone.radial_segments = 12
	cone.cap_bottom = false
	beam.mesh = cone
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.albedo_color = Color(1, 0.85, 0.5, 0.06)
	beam.material_override = bm
	beam.position = Vector3(2.2, 3.3, -6.5)
	beam.rotation_degrees = Vector3(0, 0, 80)
	vp.add_child(beam)
	var spot := SpotLight3D.new()
	spot.light_color = Color(1, 0.8, 0.5)
	spot.light_energy = 6.0
	spot.spot_range = 30.0
	spot.spot_angle = 38.0
	spot.position = Vector3(6.4, 3.3, -3.0)
	vp.add_child(spot)
	spot.look_at_from_position(spot.position, Vector3(-2.5, 0.2, 0.0))
	var fill := OmniLight3D.new()
	fill.light_color = Color(0.3, 0.8, 0.6)
	fill.light_energy = 1.2
	fill.omni_range = 12.0
	fill.position = Vector3(-5, 2, 6)
	vp.add_child(fill)
	# PS1 post: dither and grade, same shader as the game
	var layer := CanvasLayer.new()
	var rect := ColorRect.new()
	rect.size = Vector2(W, H)
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/psx_post.gdshader")
	rect.material = sm
	layer.add_child(rect)
	vp.add_child(layer)

func _mat(_shader: Shader, color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 0.55
	m.roughness = 1.0
	return m

func _text(t: String, font: Font, size: int, depth: float, pos: Vector3, mat: Material) -> void:
	var tm := TextMesh.new()
	tm.text = t
	tm.font = font
	tm.font_size = size
	tm.pixel_size = 0.016
	tm.depth = 0.12 + depth * 0.15
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = Vector3(-6, 12, 0)
	vp.add_child(mi)

func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		var img := vp.get_texture().get_image()
		img.resize(W * 3, H * 3, Image.INTERPOLATE_NEAREST)
		img.save_png(OS.get_environment("OUT"))
		quit()
	return false
