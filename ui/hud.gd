class_name Hud
extends CanvasLayer
## Minimal HUD: crosshair, interaction prompt and hold progress.

@export var player: Player

var _target: Interactable

@onready var _prompt: Label = $Root/Prompt
@onready var _hold_bar: ProgressBar = $Root/HoldBar


func _ready() -> void:
	player.focus_changed.connect(_on_focus_changed)
	player.hold_progress_changed.connect(_on_hold_progress_changed)
	_on_focus_changed(null)
	_on_hold_progress_changed(0.0)


func _process(_delta: float) -> void:
	# Prompts change while focused (e.g. "Acender" -> "Apagar"), so poll them.
	if _target:
		_prompt.text = "[E] %s" % _target.prompt


func _on_focus_changed(target: Interactable) -> void:
	_target = target
	_prompt.visible = target != null


func _on_hold_progress_changed(ratio: float) -> void:
	_hold_bar.value = ratio
	_hold_bar.visible = ratio > 0.0
