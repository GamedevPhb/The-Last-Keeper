class_name Clue
extends Interactable
## A readable note or inscription that shows its text on the HUD.

@export_multiline var text := ""


func _ready() -> void:
	interacted.connect(_on_read)


func _on_read(_by: Node) -> void:
	GameState.add_note(text)
	GameState.play("paper", global_position)
	GameState.say(text)
