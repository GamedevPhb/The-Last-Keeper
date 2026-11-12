class_name OpeningCutscene
extends CanvasLayer
## Short opening (docs/CUTSCENE_ABERTURA.md, trimmed): a camera drifts around the real island at
## dusk while the boatman's lines play in a box at the bottom. Built in code, own Camera3D plus
## a warm light so the night environment does not swallow the shots. The night clock does not run
## (GameState.in_game stays false) and the HUD steps aside (`set_panel_open`). Holding interact
## (E / Square, or a finger with touch controls) for 1 s skips to the title. Emits `finished` on
## the first playable frame, with the keeper on the pier next to the chest.

signal finished

const SKIP_HOLD := 1.0
const SKIP_FADE := 0.5
const CHARS_PER_SECOND := 30.0
const LINE_HOLD := 1.6
const PIER_SPAWN := Vector3(0.4, 0.05, 49.8)

## Each shot: start/length, camera from/to and look_from/look_to (all world space), dialogue
## lines [pause before, text] played in order, an optional title card, an optional cue.
const SHOTS := [
	{"t": 0.0, "len": 3.5, "black": true, "title": "PONTO 7\nLacrado há trinta anos."},
	{"t": 3.5, "len": 9.0, "from": Vector3(34, 1.2, 108), "to": Vector3(8, 2.0, 80),
		"look_from": Vector3(0, 9, -12), "look_to": Vector3(0, 10, -12),
		"lines": [[1.0, "Ninguém pede o Sete."], [0.8, "O senhor pediu."]], "cue": "gust"},
	{"t": 12.5, "len": 8.0, "from": Vector3(9, 1.0, 34), "to": Vector3(9, 1.0, 34),
		"look_from": Vector3(0, 1, -12), "look_to": Vector3(0, 17.5, -12),
		"lines": [[1.2, "A luz não gira desde aquela noite."]], "cue": "metal_creak"},
	{"t": 20.5, "len": 7.0, "from": Vector3(-63, 0.8, 44), "to": Vector3(-63, 0.8, 30),
		"look_from": Vector3(-44, 0, 38), "look_to": Vector3(-42, 0, 22),
		"lines": [[1.0, "Não olhe pra lá."]], "cue": "hull_knock"},
	{"t": 27.5, "len": 8.5, "from": Vector3(-5, 4.5, 40), "to": Vector3(-1, 3.0, 44),
		"look_from": Vector3(1.5, 0.0, 49), "look_to": Vector3(0.5, 0.5, 49),
		"lines": [[1.0, "Daqui o senhor segue."], [0.6, "O baú tem o que precisa."]], "cue": "pier_creak"},
	{"t": 36.0, "len": 7.0, "from": Vector3(1.0, 1.6, 46.2), "to": Vector3(1.0, 1.6, 46.2),
		"look_from": Vector3(3.0, 0.3, 54), "look_to": Vector3(8, 0.0, 70),
		"lines": [[0.8, "Conhece a regra."], [0.8, "Carga diferente, não autorize."]]},
	{"t": 43.0, "len": 5.0, "from": Vector3(0.0, 1.7, 50.5), "to": Vector3(0.0, 1.7, 50.5),
		"look_from": Vector3(-0.2, 6, 20), "look_to": Vector3(-0.2, 12, -12),
		"lines": [[0.5, "Volto às seis. Se a luz estiver acesa."]], "cue": "boat_bell"},
	{"t": 48.0, "len": 3.0, "black": true, "title": "THE LAST KEEPER"},
]

var _t := 0.0
var _shot := -1
var _done := false
var _skip_hold := 0.0
var _skip_hint := 4.0
var _skipping := -1.0
var _cues_played := {}
var _lines: Array = []
var _line := ""
var _line_shown := 0.0
var _line_hold := 0.0
var _next_line_at := 0.0
var _player: Node3D
var _camera: Camera3D
var _light: OmniLight3D
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
	_camera = Camera3D.new()
	_camera.fov = 60.0
	_camera.far = 200.0
	get_parent().add_child(_camera)
	_camera.current = true
	# Warm light riding with the camera: the night look alone leaves the shots near black.
	_light = OmniLight3D.new()
	_light.omni_range = 40.0
	_light.light_energy = 1.6
	_light.light_color = Color(1.0, 0.72, 0.5)
	_camera.add_child(_light)
	_apply(0.0)


func _process(delta: float) -> void:
	# A long hitch (the scene just loaded) must not eat the first shots.
	advance(minf(delta, 0.1))


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
			_t = SHOTS[-1].t
			_shot = -1
			_lines.clear()
			_line = ""
	if _t >= float(SHOTS[-1].t) + float(SHOTS[-1].len):
		_finish()
		return
	_apply(delta)


func skip() -> void:
	if _skipping < 0.0 and _t < float(SHOTS[-1].t):
		_skipping = SKIP_FADE


func _apply(delta: float) -> void:
	var index := _shot_at(_t)
	var shot: Dictionary = SHOTS[index]
	var local := _t - float(shot.t)
	var k := clampf(local / float(shot.len), 0.0, 1.0)
	if index != _shot:
		_shot = index
		_lines = shot.get("lines", []).duplicate()
		_next_line_at = _lines[0][0] if not _lines.is_empty() else INF
	_place_camera(shot, k)
	if shot.has("cue") and local >= 0.5 and not _cues_played.has(index):
		_cues_played[index] = true
		GameState.play(shot.cue, _camera.global_position)
	_update_titles(shot, local)
	_update_dialog(delta, local)
	if _skipping < 0.0:
		_black.modulate.a = 1.0 if shot.get("black", false) else 0.0


func _shot_at(time: float) -> int:
	for i in range(SHOTS.size() - 1, -1, -1):
		if time >= SHOTS[i].t:
			return i
	return 0


func _place_camera(shot: Dictionary, k: float) -> void:
	if shot.get("black", false):
		return
	var eased := smoothstep(0.0, 1.0, k)
	_camera.global_position = (shot.from as Vector3).lerp(shot.to, eased)
	_camera.look_at((shot.look_from as Vector3).lerp(shot.look_to, eased))


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


func _update_skip(delta: float) -> void:
	var touching := TouchControls.enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if Input.is_action_pressed("interact") or touching:
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
	var width := get_viewport().get_visible_rect().size.x
	_dialog_frame.position = Vector2((width - 260.0) / 2.0, 196)
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
	_hint = UiKit.label("Segure o toque para pular" if TouchControls.enabled else "Segure E / Quadrado para pular", 0, Color(0.8, 0.82, 0.75, 0.8))
	_hint.position = Vector2(width - 150.0, 4)
	_hint.visible = false
	root.add_child(_hint)
	_ring = SkipRing.new()
	_ring.position = Vector2(width - 20.0, 6)
	_ring.size = Vector2(12, 12)
	_ring.visible = false
	root.add_child(_ring)


## The skip progress ring, like the HUD's hold bar but round.
class SkipRing extends Control:
	var ratio := 0.0

	func _draw() -> void:
		var center := size / 2.0
		draw_arc(center, 5.0, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 2.0)
		if ratio > 0.0:
			draw_arc(center, 5.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 16, UiKit.BRASS, 2.0)
