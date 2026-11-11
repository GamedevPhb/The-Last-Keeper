class_name Clue
extends Interactable
## A readable note or inscription that shows its text on the HUD.

@export_multiline var text := ""


func _ready() -> void:
	interacted.connect(func(_by: Node) -> void: GameState.say(text))
