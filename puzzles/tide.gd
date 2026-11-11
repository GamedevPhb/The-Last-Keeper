extends Node3D
## Tide cycle. The causeway stones only stand above the water at low tide.

@export var period := 120.0 ## seconds for a full cycle
@export var low_fraction := 0.35 ## share of the cycle spent at low tide
@export var warning := 10.0 ## seconds of notice before the water rises
@export var low_y := -0.55
@export var high_y := -1.9
@export var speed := 0.3 ## meters per second

var _time := 0.0
var _low := true
var _warned := false
var _stones: Array[Node3D] = []


func _ready() -> void:
	for child in get_children():
		if child.name.begins_with("Stone"):
			_stones.append(child)


func is_low() -> bool:
	return _low


func _process(delta: float) -> void:
	_time += delta
	var phase := fmod(_time, period)
	var low := phase < period * low_fraction
	if low != _low:
		_low = low
		_warned = false
		GameState.say("A maré baixou. A passagem para o ilhéu está aberta." if low else "A maré subiu e cobriu as pedras.")
	elif low and not _warned and phase > period * low_fraction - warning:
		_warned = true
		GameState.say("A água começa a subir.")
	var target := low_y if _low else high_y
	for stone in _stones:
		stone.position.y = move_toward(stone.position.y, target, speed * delta)
