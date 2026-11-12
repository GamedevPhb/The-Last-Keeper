class_name OpeningCutscene
extends CanvasLayer
## Opening cutscene (docs/CUTSCENE_ABERTURA.md): 12 shots, ~82 s, over the real island.
## A boatman ferries the keeper to the pier at dusk. Built in code: its own Camera3D, a low-poly
## boat from primitives, the dialogue box and title cards on this layer, procedural sound cues.
## The night clock does not run (GameState.in_game stays false) and the HUD steps aside
## (`set_panel_open`). Holding interact for 1 s skips to shot 12. Emits `finished` on the
## first playable frame, with the keeper on the pier next to the chest.

signal finished

const LENGTH := 82.0
const SKIP_HOLD := 1.0
const SKIP_FADE := 0.5
const CHARS_PER_SECOND := 30.0
const LINE_HOLD := 1.5
const WATER := -1.2
const PIER_SPAWN := Vector3(0.4, 0.05, 49.8)
const DOCK := Vector3(2.7, WATER, 47.0)

## Each shot: start/length, camera ("world": from/to + look_from/look_to; "boat": local to the
## boat), boat path (or a fixed docked pose), dialogue lines [pause before, text, radio?] played
## in order, sound cues [offset, name, where], motor mode and an optional title card.
const SHOTS := [
	{"t": 0.0, "len": 5.0, "black": true, "title": "PONTO 7\nLacrado há trinta anos.", "motor": "off",
		"sounds": [[3.8, "gust", "cam"]]},
	{"t": 5.0, "len": 8.0, "cam": "world", "from": Vector3(46, -0.7, 118), "to": Vector3(10, -0.7, 120),
		"look_from": Vector3(6, 5, 0), "look_to": Vector3(-4, 5, 0),
		"boat_from": Vector3(95, WATER, 96), "boat_to": Vector3(72, WATER, 92), "motor": "drive",
		"sounds": [[0.5, "gust", "cam"]]},
	{"t": 13.0, "len": 8.0, "cam": "boat", "from": Vector3(0, 1.7, 2.3), "look_from": Vector3(0, 1.3, -8),
		"boat_from": Vector3(30, WATER, 96), "boat_to": Vector3(10, WATER, 80), "motor": "drive", "bob": true,
		"lines": [[1.0, "Ninguém pede o Sete.", false], [1.0, "O senhor pediu.", false]],
		"sounds": [[1.0, "splash", "boat"], [3.0, "splash", "boat"], [5.0, "splash", "boat"], [7.0, "splash", "boat"]]},
	{"t": 21.0, "len": 8.0, "cam": "world", "from": Vector3(9, -0.4, 34), "to": Vector3(9, -0.4, 34),
		"look_from": Vector3(0, 1, -12), "look_to": Vector3(0, 17.5, -12),
		"boat_from": Vector3(10, WATER, 80), "boat_to": Vector3(-14, WATER, 66), "motor": "drive",
		"lines": [[1.5, "A luz não gira desde aquela noite.", false]],
		"sounds": [[0.5, "gust", "cam"], [5.5, "metal_creak", Vector3(0, 17, -12)]]},
	{"t": 29.0, "len": 9.0, "cam": "world", "from": Vector3(-63, 0.6, 44), "to": Vector3(-63, 0.6, 30),
		"look_from": Vector3(-44, 0, 38), "look_to": Vector3(-42, 0, 22),
		"boat_from": Vector3(-54, WATER, 46), "boat_to": Vector3(-53, WATER, 14), "motor": "drive",
		"lines": [[3.0, "Não olhe pra lá.", false]],
		"sounds": [[1.5, "hull_knock", Vector3(-40, 0, 24)], [3.5, "hull_knock", Vector3(-40, 0, 24)],
			[5.0, "splash", Vector3(-40, 0, 24)], [6.5, "hull_knock", Vector3(-40, 0, 24)]]},
	{"t": 38.0, "len": 8.0, "cam": "boat", "from": Vector3(0.38, 1.24, 0.3), "look_from": Vector3(0.35, 1.15, -0.1),
		"boat_from": Vector3(-30, WATER, 70), "boat_to": Vector3(-12, WATER, 66), "motor": "drive", "radio_scene": true,
		"lines": [[2.0, "\"...arol Sete... Farol S...\"", true]],
		"sounds": [[1.0, "radio_voice", "boat"], [2.5, "radio_voice", "boat"], [5.6, "knob_click", "boat"]]},
	{"t": 46.0, "len": 7.0, "cam": "world", "from": Vector3(-5, 4.5, 40), "to": Vector3(-5, 4.2, 41),
		"look_from": Vector3(1.5, -0.6, 49), "look_to": Vector3(1.8, -0.6, 48),
		"boat_from": Vector3(7, WATER, 64), "boat_to": DOCK, "ease_out": true, "motor": "idle",
		"sounds": [[5.5, "pier_creak", DOCK], [6.2, "rope_slap", DOCK]]},
	{"t": 53.0, "len": 8.0, "cam": "world", "from": Vector3(0.0, 1.6, 44.6), "to": Vector3(0.0, 1.6, 44.6),
		"look_from": Vector3(2.7, 0.3, 47.4), "look_to": Vector3(2.7, 0.3, 47.4),
		"docked": true, "motor": "idle",
		"lines": [[1.0, "Daqui o senhor segue.", false], [0.4, "O baú tem o que precisa.", false]],
		"sounds": [[2.0, "splash", DOCK]]},
	{"t": 61.0, "len": 7.0, "cam": "world", "from": Vector3(1.0, 1.5, 46.2), "to": Vector3(1.0, 1.5, 46.2),
		"look_from": Vector3(2.7, 0.35, 47.4), "look_to": Vector3(2.7, 0.35, 47.4),
		"docked": true, "motor": "idle",
		"lines": [[0.5, "Conhece a regra.", false], [1.5, "Carga diferente, não autorize.", false]]},
	{"t": 68.0, "len": 5.0, "cam": "world", "from": Vector3(3.2, 0.7, 49.5), "to": Vector3(3.2, 0.7, 49.3),
		"look_from": Vector3(-0.2, 5.5, 20), "look_to": Vector3(-0.2, 6, 20),
		"docked": true, "motor": "drive",
		"lines": [[0.3, "Volto às seis.", false], [0.3, "Se a luz estiver acesa.", false]]},
	{"t": 73.0, "len": 6.0, "cam": "world", "from": Vector3(0.0, 1.7, 50.5), "to": Vector3(0.0, 1.7, 50.5),
		"look_from": Vector3(3, 0, 60), "look_to": Vector3(10, -0.5, 95),
		"boat_from": Vector3(2.7, WATER, 52), "boat_to": Vector3(14, WATER, 112), "motor": "drive", "lantern_at": 2.5,
		"sounds": [[1.5, "boat_bell", "boat"], [3.0, "boat_bell", "boat"]]},
	{"t": 79.0, "len": 3.0, "black": true, "title": "THE LAST KEEPER", "motor": "off"},
]

var _t := 0.0
var _shot := -1
var _done := false
var _skip_hold := 0.0
var _skip_hint := 0.0
var _skipping := -1.0
var _sounds_played := {}
var _lines: Array = []
var _line := ""
var _line_shown := 0.0
var _line_hold := 0.0
var _line_radio := false
var _next_line_at := 0.0
var _motor_left := 0.0
var _player: Node3D
var _camera: Camera3D
var _boat: Node3D
var _lantern: OmniLight3D
var _lantern_mat: StandardMaterial3D
var _dial_mat: StandardMaterial3D
var _hand: Node3D
var _black: ColorRect
var _title: Label
var _dialog_frame: PanelContainer
var _dialog: Label
var _hint: Label
var _ring: SkipRing


func _ready() -> void:
	layer = 15
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player:
		_player.locked = true
		_player.global_position = PIER_SPAWN
		_player.rotation = Vector3.ZERO
		_player.velocity = Vector3.ZERO
	GameState.set_panel_open(self, true)
	_build_ui()
	_build_boat()
	_camera = Camera3D.new()
	_camera.fov = 60.0
	_camera.far = 200.0
	get_parent().add_child(_camera)
	_camera.current = true
	_apply(0.0)


func _process(delta: float) -> void:
	advance(delta)


## Steps the cutscene by `delta` seconds (tests drive it directly).
func advance(delta: float) -> void:
	if _done:
		return
	_update_skip(delta)
	_t += delta
	if _skipping >= 0.0:
		_skipping -= delta
		_black.modulate.a = 1.0
		if _skipping <= 0.0:
			_skipping = -1.0
			_t = SHOTS[11].t
			_shot = -1
			_lines.clear()
			_line = ""
	if _t >= LENGTH:
		_finish()
		return
	_apply(delta)


func skip() -> void:
	if _skipping < 0.0 and _t < SHOTS[11].t:
		_skipping = SKIP_FADE


func _apply(delta: float) -> void:
	var index := _shot_at(_t)
	var shot: Dictionary = SHOTS[index]
	var local := _t - float(shot.t)
	var k := clampf(local / float(shot.len), 0.0, 1.0)
	if index != _shot:
		_shot = index
		_enter_shot(shot)
	_place_boat(shot, k)
	_place_camera(shot, k, local)
	_play_cues(index, shot, local)
	_drive_motor(shot, delta)
	_update_titles(shot, local)
	_update_dialog(delta, local)
	if shot.has("lantern_at") and local >= shot.lantern_at:
		_lantern.light_energy = 1.4
		_lantern_mat.albedo_color = Color(1.0, 0.85, 0.5)
	if shot.get("radio_scene", false):
		var reach := clampf((local - 3.5) / 1.8, 0.0, 1.0)
		_hand.position = Vector3(0.62, 1.08, 0.42).lerp(Vector3(0.4, 1.15, 0.0), reach)
		_dial_mat.albedo_color = Color(0.25, 0.9, 0.4) if local < 5.6 else Color(0.03, 0.08, 0.04)
		if local >= 5.6 and _line_radio:
			_line = ""
			_dialog_frame.visible = false
	if _skipping < 0.0:
		_black.modulate.a = 1.0 if shot.get("black", false) else 0.0


func _shot_at(time: float) -> int:
	for i in range(SHOTS.size() - 1, -1, -1):
		if time >= SHOTS[i].t:
			return i
	return 0


func _enter_shot(shot: Dictionary) -> void:
	_lines = shot.get("lines", []).duplicate()
	_next_line_at = _lines[0][0] if not _lines.is_empty() else INF
	_hand.visible = shot.get("radio_scene", false)


func _place_boat(shot: Dictionary, k: float) -> void:
	if shot.get("docked", false):
		_boat.global_position = DOCK
		_boat.rotation = Vector3.ZERO
	elif shot.has("boat_from"):
		var eased := 1.0 - pow(1.0 - k, 2.0) if shot.get("ease_out", false) else k
		var from: Vector3 = shot.boat_from
		var to: Vector3 = shot.boat_to
		_boat.global_position = from.lerp(to, eased)
		var heading := to - from
		heading.y = 0.0
		if heading.length() > 0.01:
			_boat.rotation = Vector3(0.0, atan2(-heading.x, -heading.z), 0.0)
	var wave := sin(_t * 1.6)
	_boat.rotation.z = deg_to_rad(1.5) * wave
	_boat.rotation.x = deg_to_rad(1.0) * sin(_t * 1.1)


func _place_camera(shot: Dictionary, k: float, local: float) -> void:
	if shot.get("black", false):
		return
	var eased := smoothstep(0.0, 1.0, k)
	if shot.cam == "boat":
		var frame := _boat.global_transform
		_camera.global_position = frame * (shot.from as Vector3)
		_camera.look_at(frame * (shot.look_from as Vector3))
		if shot.get("bob", false):
			_camera.rotation.z += deg_to_rad(1.0) * sin(local * 1.7)
	else:
		_camera.global_position = (shot.from as Vector3).lerp(shot.to, eased)
		_camera.look_at((shot.look_from as Vector3).lerp(shot.look_to, eased))


func _play_cues(index: int, shot: Dictionary, local: float) -> void:
	for i in shot.get("sounds", []).size():
		var cue: Array = shot.sounds[i]
		var key := "%d:%d" % [index, i]
		if local >= cue[0] and not _sounds_played.has(key):
			_sounds_played[key] = true
			GameState.play(cue[1], _where(cue[2]))


func _where(where: Variant) -> Vector3:
	if where is Vector3:
		return where
	if where == "boat":
		return _boat.global_position + Vector3.UP
	return _camera.global_position


func _drive_motor(shot: Dictionary, delta: float) -> void:
	var mode: String = shot.get("motor", "off")
	if mode == "off":
		return
	_motor_left -= delta
	if _motor_left <= 0.0:
		_motor_left = 1.0 if mode == "drive" else 1.4
		GameState.play("boat_motor" if mode == "drive" else "boat_idle", _boat.global_position)


func _update_titles(shot: Dictionary, local: float) -> void:
	if not shot.has("title"):
		_title.visible = false
		return
	_title.visible = true
	_title.text = shot.title
	var length: float = shot.len
	var fade := minf(local / 0.8, (length - local) / 0.8)
	_title.modulate.a = clampf(fade, 0.0, 1.0)


func _update_dialog(delta: float, local: float) -> void:
	if _line.is_empty():
		if not _lines.is_empty() and local >= _next_line_at:
			var entry: Array = _lines.pop_front()
			_line = entry[1]
			_line_radio = entry[2]
			_line_shown = 0.0
			_line_hold = LINE_HOLD
		else:
			_dialog_frame.visible = false
			return
	_dialog_frame.visible = true
	if _line_shown < _line.length():
		_line_shown = minf(_line_shown + CHARS_PER_SECOND * delta, _line.length())
	else:
		_line_hold -= delta
		if _line_hold <= 0.0:
			_line = ""
			if not _lines.is_empty():
				_next_line_at = local + float(_lines[0][0])
			return
	_dialog.text = _line.substr(0, int(_line_shown))
	# Radio lines tremble a little.
	_dialog.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) if _line_radio else Vector2.ZERO


func _update_skip(delta: float) -> void:
	if Input.is_action_pressed("interact"):
		_skip_hold += delta
		if _skip_hold >= SKIP_HOLD:
			skip()
	else:
		_skip_hold = 0.0
	_skip_hint = maxf(_skip_hint - delta, 0.0)
	_hint.visible = _skip_hint > 0.0 or _skip_hold > 0.0
	_ring.ratio = clampf(_skip_hold / SKIP_HOLD, 0.0, 1.0)
	_ring.visible = _skip_hold > 0.0
	_ring.queue_redraw()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var pressed := (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed()
	if pressed and not event.is_action("interact") and not event.is_action("pause"):
		_skip_hint = 2.0


func _finish() -> void:
	if _done:
		return
	_done = true
	if _player:
		_player.global_position = PIER_SPAWN
		_player.rotation = Vector3.ZERO
		_player.velocity = Vector3.ZERO
		_player.locked = false
		var eyes: Camera3D = _player.get_node("Head/Camera3D")
		eyes.current = true
	GameState.set_panel_open(self, false)
	_boat.queue_free()
	_camera.queue_free()
	finished.emit()
	queue_free()


# ---- Building

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_black = ColorRect.new()
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_black)
	_title = UiKit.heading("")
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_title)
	_dialog_frame = PanelContainer.new()
	_dialog_frame.add_theme_stylebox_override("panel", UiKit.bar())
	_dialog_frame.position = Vector2(30, 196)
	_dialog_frame.custom_minimum_size = Vector2(260, 30)
	_dialog_frame.visible = false
	root.add_child(_dialog_frame)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(250, 24)
	_dialog_frame.add_child(holder)
	_dialog = UiKit.label("", 250)
	_dialog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialog.size = Vector2(250, 24)
	holder.add_child(_dialog)
	_hint = UiKit.label("Segure E / Quadrado para pular", 0, Color(0.8, 0.82, 0.75, 0.8))
	_hint.position = Vector2(170, 4)
	_hint.visible = false
	root.add_child(_hint)
	_ring = SkipRing.new()
	_ring.position = Vector2(300, 6)
	_ring.size = Vector2(12, 12)
	_ring.visible = false
	root.add_child(_ring)


func _build_boat() -> void:
	_boat = Node3D.new()
	_boat.name = "OpeningBoat"
	get_parent().add_child(_boat)
	var wood: Material = load("res://materials/m_wood.tres")
	var metal: Material = load("res://materials/m_metal.tres")
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.06)
	_part(BoxMesh.new(), Vector3(1.6, 0.6, 4.0), Vector3(0, 0.15, 0.2), wood)
	var bow := PrismMesh.new()
	bow.size = Vector3(1.6, 0.6, 1.0)
	var bow_part := _part(bow, Vector3.ZERO, Vector3(0, 0.15, -2.3), wood)
	bow_part.rotation_degrees = Vector3(-90, 0, 0)
	_part(BoxMesh.new(), Vector3(1.3, 0.08, 1.3), Vector3(0, 1.75, 0.4), metal) # roof
	for x: float in [-0.6, 0.6]:
		_part(BoxMesh.new(), Vector3(0.06, 1.3, 0.06), Vector3(x, 1.1, -0.2), metal)
		_part(BoxMesh.new(), Vector3(0.06, 1.3, 0.06), Vector3(x, 1.1, 1.0), metal)
	_part(BoxMesh.new(), Vector3(1.2, 0.55, 0.08), Vector3(0, 0.75, -0.2), wood) # dashboard
	_part(BoxMesh.new(), Vector3(0.26, 0.15, 0.1), Vector3(0.35, 1.1, -0.15), metal) # radio
	var dial := QuadMesh.new()
	dial.size = Vector2(0.12, 0.06)
	_dial_mat = StandardMaterial3D.new()
	_dial_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dial_mat.albedo_color = Color(0.25, 0.9, 0.4)
	_part(dial, Vector3.ZERO, Vector3(0.33, 1.11, -0.095), _dial_mat)
	# The boatman: a dark silhouette at the helm, cap on.
	var body := CapsuleMesh.new()
	body.radius = 0.22
	body.height = 1.3
	_part(body, Vector3.ZERO, Vector3(0, 1.0, 0.45), dark)
	var cap := CylinderMesh.new()
	cap.top_radius = 0.16
	cap.bottom_radius = 0.2
	cap.height = 0.1
	_part(cap, Vector3.ZERO, Vector3(0, 1.7, 0.45), dark)
	_hand = _part(BoxMesh.new(), Vector3(0.07, 0.05, 0.2), Vector3(0.62, 1.08, 0.42), dark)
	var lamp := SphereMesh.new()
	lamp.radius = 0.06
	lamp.height = 0.12
	_lantern_mat = StandardMaterial3D.new()
	_lantern_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_lantern_mat.albedo_color = Color(0.2, 0.15, 0.1)
	_part(lamp, Vector3.ZERO, Vector3(0, 0.6, -2.7), _lantern_mat)
	_lantern = OmniLight3D.new()
	_lantern.position = Vector3(0, 0.7, -2.7)
	_lantern.omni_range = 6.0
	_lantern.light_energy = 0.0
	_lantern.light_color = Color(1.0, 0.8, 0.5)
	_boat.add_child(_lantern)


func _part(mesh: Mesh, box_size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	if mesh is BoxMesh and box_size != Vector3.ZERO:
		(mesh as BoxMesh).size = box_size
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.position = at
	_boat.add_child(part)
	return part


## The skip progress ring, like the HUD's hold bar but round.
class SkipRing extends Control:
	var ratio := 0.0

	func _draw() -> void:
		var center := size / 2.0
		draw_arc(center, 5.0, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 2.0)
		if ratio > 0.0:
			draw_arc(center, 5.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 16, UiKit.BRASS, 2.0)
