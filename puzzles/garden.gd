extends "res://puzzles/station.gd"
## Garden and extra cistern (night 3+): one harvest per night of biscuits and water.

const BUSH := preload("res://materials/m_bush.tres")
const WOOD := preload("res://materials/m_wood.tres")
const BISCUITS := 2
const WATER := 1


func _init() -> void:
	unlock_id = "garden"
	title = "Colher da horta e da cisterna"
	hold_time = 2.0
	per_night = 1


func _use(_by: Node) -> void:
	spend_use()
	var at := global_position + Vector3(0.0, 0.5, 0.0)
	GameState.give("biscuit", BISCUITS, at)
	GameState.give("water", WATER, at)
	GameState.play("eat", global_position)
	GameState.say("Você colhe %d bolachas e enche uma garrafa na cisterna." % BISCUITS)


func _build_body(root: Node3D) -> void:
	_box(root, Vector3(2.0, 0.4, 1.2), Vector3(0.0, 0.2, 0.0), BUSH)
	_box(root, Vector3(0.7, 0.9, 0.7), Vector3(1.7, 0.45, 0.0), WOOD)
