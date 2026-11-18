extends Node3D
## Tide cycle. The causeway stones only stand above the water at low tide.

@export var period := 120.0 ## seconds for a full cycle
@export var low_fraction := 0.35 ## share of the cycle spent at low tide
@export var warning := 10.0 ## seconds of notice before the water rises
@export var low_y := -0.55
@export var high_y := -1.9
@export var speed := 0.3 ## meters per second
@export var announce := true ## false: nao fala no HUD (evita duplicar a mensagem)

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


## Real seconds until the tide turns (low -> high or high -> low).
func seconds_to_change() -> float:
	var phase := fmod(_time, period)
	return (period * low_fraction - phase) if _low else (period - phase)


## Tide board on the beach (`puzzles/hint_plate.gd`, source = this node).
func hint_title() -> String:
	return "MARÉ BAIXA\nPASSE" if _low else "MARÉ ALTA\nESPERE"


func hint_text() -> String:
	var left := roundi(seconds_to_change())
	var now := ("Maré baixa: as pedras seguram por mais uns %d s." % left) if _low else ("Maré alta: as pedras voltam em uns %d s." % left)
	return "Régua de maré, marcada pelo vigia 4: \"Pedra seca, passe. Ouviu a água, volte. Ninguém espera no meio.\" %s" % now


func _process(delta: float) -> void:
	_time += delta
	var phase := fmod(_time, period)
	var low := phase < period * low_fraction
	if low != _low:
		_low = low
		_warned = false
		if announce:
			GameState.say("A maré baixou. A passagem para o ilhéu está aberta." if low else "A maré subiu e cobriu as pedras.")
	elif low and not _warned and phase > period * low_fraction - warning:
		_warned = true
		if announce:
			GameState.say("A água começa a subir.")
	var target := low_y if _low else high_y
	for stone in _stones:
		stone.position.y = move_toward(stone.position.y, target, speed * delta)
