class_name Hud
extends CanvasLayer
## Lean HUD: crosshair dot, clock, and things that appear only when they matter.
## The objective (with distance and heading) shows for a few seconds when it changes, the
## inventory strip when it changes, messages fade on their own, the interaction prompt sits
## in the lower third, and the whole HUD hides while a puzzle panel is open
## (`GameState.panel_changed`), since panels show their own messages.
## It also owns the touch controls (`ui/touch_controls.gd`), which show only on touch devices.

const OBJECTIVE_TIME := 8.0
const STATUS_TIME := 5.0
const HINTS_TIME := 8.0
const FADE := 1.0
const INVENTORY_PANEL := preload("res://ui/inventory_panel.gd")

@export var player: Player

var _target: Interactable
var _toast_left := 0.0
var _objective_left := 0.0
var _status_left := 0.0
var _hints_left := HINTS_TIME
var _last_objective := ""
var _last_status := ""
var _gamepad := false
var _objective_frame: Panel
var _toast_frame: Panel
var _prompt_frame: Panel
var _status_frame: Panel
## 8x8 critical-status icons, bottom-left, only while a status is critical (GDD 4.10).
var _critical_icons := {}
var _blink := 0.0

@onready var _root: Control = $Root
@onready var _prompt: Label = $Root/Prompt
@onready var _hold_bar: ProgressBar = $Root/HoldBar
@onready var _toast: Label = $Root/Toast
@onready var _status: Label = $Root/Status
@onready var _objective: Label = $Root/Objective
@onready var _compass: Label = $Root/Compass
@onready var _clock: Label = $Root/Clock
@onready var _hints: Label = $Root/Hints


func _ready() -> void:
	player.focus_changed.connect(_on_focus_changed)
	player.hold_progress_changed.connect(_on_hold_progress_changed)
	GameState.toast.connect(_on_toast)
	GameState.changed.connect(_refresh_status)
	GameState.panel_changed.connect(_on_panel_changed)
	_toast.text = ""
	_build_frames()
	_on_focus_changed(null)
	_on_hold_progress_changed(0.0)
	_toast.visible = false
	_toast_frame.visible = false
	_compass.visible = false # the heading now rides on the objective line
	_refresh_status()
	_update_hints()
	var touch := TouchControls.new()
	touch.name = "TouchControls"
	touch.player = player
	add_child(touch)
	get_viewport().size_changed.connect(_layout)
	_layout()
	var x := 4.0
	for key: String in ["thirst", "hunger", "health"]:
		var icon := TextureRect.new()
		icon.texture = INVENTORY_PANEL.status_texture(key)
		icon.position = Vector2(x, 228)
		icon.size = Vector2(8, 8)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		_root.add_child(icon)
		_critical_icons[key] = icon
		x += 10.0


func _build_frames() -> void:
	_status_frame = _frame(Rect2(2, 2, 150, 13), _status)
	_objective_frame = _frame(Rect2(2, 17, 176, 36), _objective)
	_toast_frame = _frame(Rect2(20, 202, 280, 26), _toast)
	_prompt_frame = _frame(Rect2(100, 172, 120, 14), _prompt)
	_status.position = Vector2(6, 3)
	_status.size = Vector2(142, 11)
	_objective.position = Vector2(7, 20)
	_objective.size = Vector2(166, 60)
	_toast.offset_left = 26.0
	_toast.offset_right = -26.0
	_toast.offset_top = -37.0
	_toast.offset_bottom = -13.0
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Prompt and hold bar live in the lower third, clear of the crosshair.
	_prompt.offset_top = 52.0
	_prompt.offset_bottom = 66.0
	_hold_bar.offset_top = 68.0
	_hold_bar.offset_bottom = 70.0
	_clock.anchor_left = 1.0
	_clock.anchor_right = 1.0
	_clock.offset_left = -40.0
	_clock.offset_right = -4.0
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock.add_theme_color_override("font_color", Color(UiKit.BRASS, 0.85))
	_hints.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7, 0.55))
	for label: Label in [_status, _objective, _toast, _prompt, _clock, _compass]:
		label.add_theme_constant_override("outline_size", 0)


## Centres the strips on wide screens (aspect "expand" on phones); 320 wide keeps the PC layout.
func _layout() -> void:
	var margin := (get_viewport().get_visible_rect().size.x - 280.0) / 2.0
	_toast_frame.position.x = margin
	_toast.offset_left = margin + 6.0
	_toast.offset_right = -(margin + 6.0)


## A themed strip placed just behind `label`.
func _frame(rect: Rect2, label: Control) -> Panel:
	var frame := Panel.new()
	frame.position = rect.position
	frame.size = rect.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UiKit.bar())
	_root.add_child(frame)
	_root.move_child(frame, label.get_index())
	return frame


func _process(delta: float) -> void:
	_clock.text = GameState.clock_text()
	var objective := GameState.objective()
	if objective != _last_objective:
		_last_objective = objective
		_objective_left = OBJECTIVE_TIME
	if _objective_left > 0.0:
		_objective_left -= delta
		_objective.text = objective + _target_line()
		var lines := _objective.get_line_count()
		_objective_frame.size.y = lines * (_objective.get_line_height() + 1) + 6
	_fade(_objective_left, [_objective, _objective_frame])
	_toast_left -= delta
	_fade(_toast_left, [_toast, _toast_frame])
	_status_left -= delta
	_fade(_status_left, [_status, _status_frame])
	_hints_left -= delta
	_fade(0.0 if TouchControls.enabled else _hints_left, [_hints])
	_blink += delta
	var critical: Dictionary = GameState.critical()
	for key: String in _critical_icons:
		var icon: TextureRect = _critical_icons[key]
		icon.visible = critical[key] and not _hints.visible
		icon.modulate.a = 0.55 + 0.45 * sin(_blink * 2.0)
	# Prompts change while focused (e.g. a counter in the text), so poll them.
	if _target:
		_prompt.text = _target.prompt if TouchControls.enabled else "[%s] %s" % ["Quadrado" if _gamepad else "E", _target.prompt]
		var width := _prompt.get_theme_font("font").get_string_size(_prompt.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE).x + 14.0
		_prompt_frame.size.x = width
		_prompt_frame.position.x = get_viewport().get_visible_rect().size.x / 2.0 - width / 2.0


## Shows `items` while `left` > 0, fading out over the last second.
func _fade(left: float, items: Array) -> void:
	for item: CanvasItem in items:
		item.visible = left > 0.0
		item.modulate.a = clampf(left / FADE, 0.0, 1.0)


func _on_panel_changed(open: bool) -> void:
	_root.visible = not open
	if not open:
		_objective_left = maxf(_objective_left, 3.0)


func _on_focus_changed(target: Interactable) -> void:
	_target = target
	_prompt.visible = target != null
	if _prompt_frame:
		_prompt_frame.visible = _prompt.visible


func _on_hold_progress_changed(ratio: float) -> void:
	_hold_bar.value = ratio
	_hold_bar.visible = ratio > 0.0


func _on_toast(text: String) -> void:
	_toast.text = text
	_toast_left = clampf(2.5 + text.length() * 0.035, 3.0, 6.0)


func _refresh_status() -> void:
	var text := "Óleo %d  Comb. %d  Navios %d/%d%s" % [
		GameState.oil_cans, GameState.fuel_cans, GameState.ships_saved,
		GameState.ships_saved + GameState.ships_lost, "  [gerador]" if GameState.generator_on else ""]
	if text != _last_status:
		_last_status = text
		_status.text = text
		_status_left = STATUS_TIME


func _heading() -> String:
	var forward := -player.global_transform.basis.z
	var degrees := rad_to_deg(atan2(forward.x, -forward.z))
	return ["N", "NE", "L", "SE", "S", "SO", "O", "NO"][posmod(roundi(degrees / 45.0), 8)]


func _input(event: InputEvent) -> void:
	var pad := event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5)
	var keys := event is InputEventKey or event is InputEventMouseButton
	if (pad and not _gamepad) or (keys and _gamepad):
		_gamepad = pad
		_update_hints()
		_hints_left = HINTS_TIME


func _update_hints() -> void:
	_hints.text = "[Triângulo] Inventário  [↑] Rádio  [L1] Livro  [R1] Lanterna  [Options] Pausa" if _gamepad else "[Tab] Inventário  [R] Rádio  [J] Livro  [F] Lanterna  [Esc] Pausa"


## Distance and direction to the current objective, relative to where the player is looking.
func _target_line() -> String:
	var target := GameState.objective_target()
	if target == Vector3.INF:
		return "\nRumo %s" % _heading()
	var to := target - player.global_position
	to.y = 0.0
	var forward := -player.global_transform.basis.z
	var bearing := rad_to_deg(atan2(to.x, -to.z)) - rad_to_deg(atan2(forward.x, -forward.z))
	var side: String = ["à frente", "à frente, direita", "à direita", "atrás, direita", "atrás", "atrás, esquerda", "à esquerda", "à frente, esquerda"][posmod(roundi(bearing / 45.0), 8)]
	return "\n%d m, %s · rumo %s" % [roundi(to.length()), side, _heading()]
