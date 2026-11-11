class_name Hud
extends CanvasLayer
## Minimal HUD: crosshair, interaction prompt and hold progress.

@export var player: Player

var _target: Interactable
var _toast_left := 0.0

@onready var _prompt: Label = $Root/Prompt
@onready var _hold_bar: ProgressBar = $Root/HoldBar
@onready var _toast: Label = $Root/Toast
@onready var _status: Label = $Root/Status


func _ready() -> void:
	player.focus_changed.connect(_on_focus_changed)
	player.hold_progress_changed.connect(_on_hold_progress_changed)
	_on_focus_changed(null)
	_on_hold_progress_changed(0.0)
	GameState.toast.connect(_on_toast)
	GameState.changed.connect(_refresh_status)
	_toast.text = ""
	_refresh_status()


func _process(delta: float) -> void:
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.visible = _toast_left > 0.0
	# Prompts change while focused (e.g. "Acender" -> "Apagar"), so poll them.
	if _target:
		_prompt.text = "[E] %s" % _target.prompt


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
