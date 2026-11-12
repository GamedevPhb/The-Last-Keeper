extends Node3D
## Title screen: buttons on the left, the lit lighthouse island slowly turning on the right.

const GAME := "res://main.tscn"
const SAVE := preload("res://save_game.gd")
const SAVE_SLOTS := preload("res://ui/save_slots.gd")
const ORBIT_CENTER := Vector3(0.0, 4.0, -6.0)
const ORBIT_RADIUS := 52.0
const ORBIT_HEIGHT := 24.0

var _camera: Camera3D
var _angle := 2.2
var _buttons: VBoxContainer
var _settings: SettingsPanel
var _logo: TextureRect
var _slots ## SaveSlots panel (ui/save_slots.gd)
var _continue: Button
var _hint: Label


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
	beacon.showcase()
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
	var start := UiKit.button("Novo jogo", _open_slots.bind("new"))
	_buttons.add_child(start)
	_continue = UiKit.button("Continuar", _open_slots.bind("load"))
	_continue.disabled = not _has_saves()
	_buttons.add_child(_continue)
	_buttons.add_child(UiKit.button("Opções", _open_settings))
	_buttons.add_child(UiKit.button("Sair", func() -> void: get_tree().quit()))
	start.grab_focus.call_deferred()
	_hint = UiKit.label("", 0, Color(0.55, 0.65, 0.6))
	_hint.position = Vector2(18, 218)
	layer.add_child(_hint)
	_update_hint()
	Input.joy_connection_changed.connect(func(_d: int, _c: bool) -> void: _update_hint())
	var footer := UiKit.label("pré-alpha  ·  Farol 7", 0, Color(0.45, 0.55, 0.5))
	layer.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 4)
	footer.offset_left = 10
	footer.offset_right = 200
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_close_settings)
	layer.add_child(_settings)
	# Slots are centred in whatever shape the viewport has; the CenterContainer lets clicks through.
	var slot_center := CenterContainer.new()
	slot_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	slot_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(slot_center)
	_slots = SAVE_SLOTS.new()
	_slots.visible = false
	_slots.chosen.connect(_on_slot_chosen)
	_slots.closed.connect(_close_slots)
	slot_center.add_child(_slots)


func _has_saves() -> bool:
	for slot in range(1, SAVE.SLOTS + 1):
		if SAVE.exists(slot):
			return true
	return false


func _open_slots(mode: String) -> void:
	_buttons.get_parent().visible = false
	_logo.visible = false
	_slots.open(mode)


func _close_slots() -> void:
	_buttons.get_parent().visible = true
	_logo.visible = true
	_continue.disabled = not _has_saves()
	(_buttons.get_child(0) as Button).grab_focus()


## A new game plays the opening; a saved one is applied once main.tscn is ready.
func _on_slot_chosen(slot: int, data: Dictionary) -> void:
	GameState.save_slot = slot
	GameState.pending_load = data
	GameState.play_intro = data.is_empty()
	_start()


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


## Small controller hint, shown only while a pad is connected (320x240 safe).
func _update_hint() -> void:
	_hint.text = "A/Cross: confirmar · B/Circle: voltar" if not Input.get_connected_joypads().is_empty() else ""


## A pad press with nothing focused (e.g. after a mouse click) restores focus so navigation never gets stuck.
func _input(event: InputEvent) -> void:
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	if get_viewport().gui_get_focus_owner() != null or _buttons == null or not _buttons.is_visible_in_tree():
		return
	for child in _buttons.get_children():
		var button := child as Button
		if button and not button.disabled:
			button.grab_focus()
			return
