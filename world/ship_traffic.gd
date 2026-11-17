extends Node3D
## Spawns the ship of the active radio call (GameState.active_call) and plays out its verdict
## (GameState.ship_event). Ships are built on first use.

var _ships := {}
var _last := ""


func _ready() -> void:
	add_to_group("ship_traffic")
	GameState.ship_event.connect(_on_ship_event)


func _process(_delta: float) -> void:
	var current: String = GameState.active_call.get("call", "")
	if current == _last:
		return
	_last = current
	if current != "":
		_ship(current).announce()


func ship(ship_name: String) -> Ship:
	return _ship(ship_name)


func _ship(ship_name: String) -> Ship:
	if _ships.has(ship_name):
		return _ships[ship_name]
	var index := 0
	for i in GameState.SHIPS.size():
		if GameState.SHIPS[i].call == ship_name:
			index = i
	var built := Ship.new()
	add_child(built)
	built.setup(index, ship_name)
	_ships[ship_name] = built
	return built


func _on_ship_event(ship_name: String, outcome: String) -> void:
	_ship(ship_name).resolve(outcome)


## Story scene "aurora": dresses the ship as the Santa Aurora (or back).
func haunt(ship_name: String, on: bool) -> void:
	_ship(ship_name).haunt(on)


func captain_position(ship_name: String) -> Vector3:
	return _ship(ship_name).captain.global_position + Vector3(0.0, 1.4, 0.0)
