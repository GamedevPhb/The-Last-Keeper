extends OmniLight3D
## Light that follows a breaker circuit, or the generator itself when `circuit` is empty.

@export var circuit := "house"


func _ready() -> void:
	GameState.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	visible = GameState.generator_on if circuit.is_empty() else GameState.powered(circuit)
