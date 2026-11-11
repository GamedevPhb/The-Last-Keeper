class_name Hud
extends CanvasLayer
## Minimal HUD: crosshair, interaction prompt and hold progress.

@export var player: Player

var _target: Interactable
var _toast_left := 0.0
var _gamepad := false

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
	_refresh_status()
	_update_hints()


func _process(delta: float) -> void:
	_objective.text = "Objetivo: " + GameState.objective() + _target_line()
	_clock.text = GameState.clock_text()
	_compass.text = "Rumo %s" % _heading()
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	# Prompts change while focused (e.g. "Acender" -> "Apagar"), so poll them.
	if _target:
		_prompt.text = "[%s] %s" % ["Quadrado" if _gamepad else "E", _target.prompt]


func _on_focus_changed(target: Interactable) -> void:
	_target = target
	_prompt.visible = target != null


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
