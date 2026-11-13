extends "res://puzzles/station.gd"
## Fence and door reinforcement (night 3+): each level spends wood and lasts the whole run.
## Level 1 braces the fence, level 2 the house door. `GameState.fence_level` thins and delays
## the invasion waves (`world/invasion.gd`).

const WOOD := preload("res://materials/m_wood.tres")
const COSTS := [4, 6] ## wood per level (a stack is 8; total 10 = ~3 cans of oil)
const MAX_LEVEL := 2


func _init() -> void:
	unlock_id = "fortify"
	title = "Reforçar a cerca"
	hold_time = 1.5
	per_night = 0


func _can_use() -> bool:
	return is_open() and GameState.fence_level < MAX_LEVEL


func _prompt() -> String:
	if GameState.fence_level >= MAX_LEVEL:
		return "Cerca e porta reforçadas"
	return "%s (madeira x%d)" % ["Reforçar a cerca" if GameState.fence_level == 0 else "Reforçar a porta", COSTS[GameState.fence_level]]


func _use(_by: Node) -> void:
	var cost: int = COSTS[GameState.fence_level]
	if GameState.inventory.count("wood") < cost or not GameState.inventory.remove("wood", cost):
		GameState.say("Faltam tábuas: são %d de madeira." % cost)
		return
	GameState.fence_level += 1
	GameState.play("clunk", global_position)
	GameState.say("Reforçada a cerca." if GameState.fence_level == 1 else "A porta da casa agora aguenta.")
	GameState.autosave()


func save_state() -> Dictionary:
	return {}


func _build_body(root: Node3D) -> void:
	_box(root, Vector3(3.0, 1.2, 0.2), Vector3(0.0, 0.6, 0.0), WOOD)
