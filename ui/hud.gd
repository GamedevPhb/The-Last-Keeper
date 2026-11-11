class_name Hud
extends CanvasLayer
## Minimal HUD: crosshair, interaction prompt and hold progress.

@export var player: Player

var _target: Interactable
var _toast_left := 0.0
var _gamepad := false
var _top_bar: Panel
var _objective_frame: Panel
var _toast_frame: Panel
var _prompt_frame: Panel

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
	_on_focus_changed(null)
	_on_hold_progress_changed(0.0)
	GameState.toast.connect(_on_toast)
	GameState.changed.connect(_refresh_status)
	_toast.text = ""
	_toast_left = 0.0
	_build_frames()
	_toast_frame.visible = false
	_prompt_frame.visible = false
	_refresh_status()
	_update_hints()


func _build_frames() -> void:
	var root: Control = $Root
	_top_bar = _frame(root, Rect2(0, 0, 320, 15), _status)
	_objective_frame = _frame(root, Rect2(2, 17, 190, 40), _objective)
	_toast_frame = _frame(root, Rect2(8, 186, 304, 34), _toast)
	_prompt_frame = _frame(root, Rect2(100, 128, 120, 14), _prompt)
	_objective.position = Vector2(7, 20)
	_objective.size = Vector2(180, 34)
	_toast.offset_left = 12.0
	_toast.offset_right = -12.0
	_toast.offset_top = -52.0
	_toast.offset_bottom = -22.0
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status.position = Vector2(5, 2)
	_compass.position.y = 2
	_clock.add_theme_color_override("font_color", UiKit.BRASS)
	_compass.add_theme_color_override("font_color", UiKit.SEA)
	_hints.add_theme_color_override("font_color", Color(0.7, 0.75, 0.7, 0.55))
	for label: Label in [_status, _objective, _toast, _prompt, _clock, _compass]:
		label.add_theme_constant_override("outline_size", 0)


## A themed strip placed just behind `label`.
func _frame(root: Control, rect: Rect2, label: Control) -> Panel:
	var frame := Panel.new()
	frame.position = rect.position
	frame.size = rect.size
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", UiKit.bar())
	root.add_child(frame)
	root.move_child(frame, label.get_index())
	return frame


func _process(delta: float) -> void:
	_objective.text = GameState.objective() + _target_line()
	_clock.text = GameState.clock_text()
	_compass.text = "Rumo %s" % _heading()
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
		_toast_frame.visible = _toast.visible
	# Prompts change while focused (e.g. "Acender" -> "Apagar"), so poll them.
	if _target:
		_prompt.text = "[%s] %s" % ["Quadrado" if _gamepad else "E", _target.prompt]
		var width := _prompt.get_theme_font("font").get_string_size(_prompt.text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE).x + 14.0
		_prompt_frame.size.x = width
		_prompt_frame.position.x = 160.0 - width / 2.0


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
	_toast_left = 4.5


func _refresh_status() -> void:
	_status.text = "Óleo %d  Comb. %d  Navios %d/%d%s" % [
		GameState.oil_cans, GameState.fuel_cans, GameState.ships_saved,
		GameState.ships_saved + GameState.ships_lost, "  [gerador]" if GameState.generator_on else ""]


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


func _update_hints() -> void:
	_hints.text = "[Triângulo] Inventário  [L1] Livro  [R1] Lanterna  [Options] Pausa" if _gamepad else "[Tab] Inventário  [J] Livro  [F] Lanterna  [Esc] Pausa"


## Distance and direction to the current objective, relative to where the player is looking.
func _target_line() -> String:
	var target := GameState.objective_target()
	if target == Vector3.INF:
		return ""
	var to := target - player.global_position
	to.y = 0.0
	var forward := -player.global_transform.basis.z
	var bearing := rad_to_deg(atan2(to.x, -to.z)) - rad_to_deg(atan2(forward.x, -forward.z))
	var side: String = ["à frente", "à frente, direita", "à direita", "atrás, direita", "atrás", "atrás, esquerda", "à esquerda", "à frente, esquerda"][posmod(roundi(bearing / 45.0), 8)]
	return "\nAlvo: %d m, %s" % [roundi(to.length()), side]
