class_name Beacon
extends Node3D
## The lighthouse lamp: rotating light beam, toggled through its Interactable.
## Placeholder for the full lamp system (oil, clockwork, lens) planned in the GDD.

@export var rotation_speed := 0.6 ## radians per second
@export var lit := true:
	set(value):
		lit = value
		if is_node_ready():
			_apply()

@onready var _head: Node3D = $Head
@onready var _bulb: MeshInstance3D = $Bulb
@onready var _glow: OmniLight3D = $Glow
@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_apply()


func _process(delta: float) -> void:
	if lit:
		_head.rotate_y(rotation_speed * delta)


func _apply() -> void:
	_head.visible = lit
	_bulb.visible = lit
	_glow.visible = lit
	_interactable.prompt = "Apagar a lâmpada" if lit else "Acender a lâmpada"


func _on_interacted(_by: Node) -> void:
	lit = not lit
