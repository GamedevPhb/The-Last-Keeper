extends "res://puzzles/station.gd"
## Fishing trap on the north pier (GDD: sustento). Hold to haul it: fish, sometimes a bottle of water.

const WOOD := preload("res://materials/m_wood.tres")
const FISH_MIN := 1
const FISH_MAX := 2
const WATER_CHANCE := 0.5


func _init() -> void:
	unlock_id = "fishing"
	title = "Puxar a armadilha de pesca"
	hold_time = 2.5
	per_night = 2


func _prompt() -> String:
	return "%s (%d)" % [title, uses_left()]


func _use(_by: Node) -> void:
	spend_use()
	var fish := randi_range(FISH_MIN, FISH_MAX)
	GameState.give("fish", fish, global_position + Vector3(0.0, 0.5, 0.0))
	var line := "A armadilha traz %d peixe%s" % [fish, "" if fish == 1 else "s"]
	if randf() < WATER_CHANCE:
		GameState.give("water", 1, global_position + Vector3(0.0, 0.5, 0.0))
		line += " e uma garrafa d'água"
	GameState.play("clunk", global_position)
	GameState.say(line + ".")


func _build_body(root: Node3D) -> void:
	_box(root, Vector3(1.0, 0.5, 0.7), Vector3(0.0, 0.25, 0.0), WOOD)
