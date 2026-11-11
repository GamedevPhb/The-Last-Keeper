extends Node3D
## Title screen: buttons on the left, the lit lighthouse island slowly turning on the right.

const GAME := "res://main.tscn"
const ORBIT_CENTER := Vector3(0.0, 4.0, -6.0)
const ORBIT_RADIUS := 52.0
const ORBIT_HEIGHT := 24.0

var _camera: Camera3D
var _angle := 2.2
var _buttons: VBoxContainer
var _settings: SettingsPanel
var _logo: TextureRect


func _ready() -> void:
	GameState.reset()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_world()
	_build_ui()


func _process(delta: float) -> void:
	_angle += delta * 0.06
	_camera.position = ORBIT_CENTER + Vector3(cos(_angle) * ORBIT_RADIUS, ORBIT_HEIGHT, sin(_angle) * ORBIT_RADIUS)
	_camera.look_at(ORBIT_CENTER)


func _build_world() -> void:
	var island: Node3D = load("res://world/island.tscn").instantiate()
	add_child(island)
	var beacon: Beacon = island.get_node("Lighthouse/Beacon")
	beacon.oil = 1.0
	beacon.wound = 1.0
	beacon.oil_burn = 0.0
	beacon.spring_unwind = 0.0
	beacon.lit = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.04, 0.07, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.42, 0.38)
	env.ambient_light_energy = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.04, 0.07, 0.06)
	env.fog_density = 0.008
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var moon := DirectionalLight3D.new()
	moon.rotation = Vector3(-0.9, 0.6, 0.0)
	moon.light_color = Color(0.5, 0.7, 0.6)
	moon.light_energy = 0.9
	add_child(moon)
	_camera = Camera3D.new()
	_camera.fov = 50.0
	_camera.far = 400.0
	_camera.h_offset = -9.0 # shifts the island to the right half of the screen
	add_child(_camera)
	_camera.current = true


func _build_ui() -> void:
	var filter_layer := CanvasLayer.new()
	filter_layer.layer = 5
	var filter := ColorRect.new()
	filter.set_anchors_preset(Control.PRESET_FULL_RECT)
	filter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/psx_post.gdshader")
	filter.material = material
	filter_layer.add_child(filter)
	add_child(filter_layer)

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_logo = TextureRect.new()
	var logo := _logo
	logo.texture = load("res://ui/logo.png")
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo.position = Vector2(8, 10)
	layer.add_child(logo)
	var left := PanelContainer.new()
	left.position = Vector2(18, 112)
	left.custom_minimum_size = Vector2(112, 0)
	layer.add_child(left)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 5)
	left.add_child(_buttons)
	var start := UiKit.button("Iniciar", _start)
	_buttons.add_child(start)
	_buttons.add_child(UiKit.button("Opções", _open_settings))
	_buttons.add_child(UiKit.button("Sair", func() -> void: get_tree().quit()))
	start.grab_focus()
	var footer := UiKit.label("pré-alpha  ·  Farol 7", 0, Color(0.45, 0.55, 0.5))
	footer.position = Vector2(10, 228)
	layer.add_child(footer)
	_settings = SettingsPanel.new()
	_settings.position = Vector2(8, 4)
	_settings.visible = false
	_settings.closed.connect(_close_settings)
	layer.add_child(_settings)


func _start() -> void:
	get_tree().change_scene_to_file(GAME)


func _open_settings() -> void:
	_buttons.get_parent().visible = false
	_logo.visible = false
	_settings.visible = true


func _close_settings() -> void:
	_settings.visible = false
	_buttons.get_parent().visible = true
	_logo.visible = true
	(_buttons.get_child(0) as Button).grab_focus()
