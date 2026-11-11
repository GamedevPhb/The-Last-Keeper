class_name Interactable
extends Area3D
## Something the player can aim at and use with the "interact" action.
## Owners connect to `interacted` and keep `prompt` up to date.

signal interacted(by: Node)

## Physics layer 3 ("interact"). The player's ray masks world + interact,
## so walls block interaction through them.
const LAYER := 1 << 2

@export var prompt := "Interagir"
## Seconds the button must be held. 0 = instant press.
@export_range(0.0, 10.0, 0.1) var hold_time := 0.0
@export var enabled := true


func _init() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func interact(by: Node) -> void:
	if enabled:
		interacted.emit(by)
