extends "res://puzzles/station.gd"
## Workshop (night 2+): opens `ui/workshop_console.gd`; recipes paid in scrap and coal.

const CONSOLE := preload("res://ui/workshop_console.gd")
const METAL := preload("res://materials/m_metal.tres")
## [output item, amount, {cost item: amount}]. Provisional.
const RECIPES := [
	["ammo_pistol", 6, {"scrap": 2, "coal": 1}],
	["shells", 2, {"scrap": 2, "coal": 1}],
	["battery", 1, {"scrap": 1, "coal": 1}],
	["lens_cleaner", 1, {"scrap": 2}],
]

var _console: Node


func _init() -> void:
	unlock_id = "workshop"
	title = "Oficina"
	per_night = 0


func can_craft(index: int) -> bool:
	for id: String in RECIPES[index][2]:
		if GameState.inventory.count(id) < RECIPES[index][2][id]:
			return false
	return true


## Pays the cost and hands over the product. Returns false when something is missing.
func craft(index: int) -> bool:
	if not is_open() or not can_craft(index):
		return false
	for id: String in RECIPES[index][2]:
		GameState.inventory.remove(id, RECIPES[index][2][id])
	GameState.give(RECIPES[index][0], RECIPES[index][1], global_position + Vector3(0.0, 0.5, 0.8))
	GameState.play("clunk", global_position)
	return true


func _use(by: Node) -> void:
	if _console == null:
		_console = CONSOLE.new()
		_console.workshop = self
		add_child(_console)
	_console.open(by as Player)


func save_state() -> Dictionary:
	return {}


func _build_body(root: Node3D) -> void:
	_box(root, Vector3(1.6, 0.9, 0.8), Vector3(0.0, 0.45, 0.0), METAL)
