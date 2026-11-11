extends Node
## Run-wide state shared by the puzzles: carried items, power and HUD messages.

signal toast(text: String)
signal changed

## How many circuits the generator can feed at once.
const POWER_CAPACITY := 2

var oil_cans := 0:
	set(value):
		oil_cans = value
		changed.emit()
var fuel_cans := 0:
	set(value):
		fuel_cans = value
		changed.emit()
var generator_on := false:
	set(value):
		generator_on = value
		changed.emit()
var ships_saved := 0:
	set(value):
		ships_saved = value
		changed.emit()
var ships_lost := 0:
	set(value):
		ships_lost = value
		changed.emit()
var breakers := {"radio": false, "house": false, "motor": false}


func say(text: String) -> void:
	toast.emit(text)


func powered(circuit: String) -> bool:
	return generator_on and breakers[circuit]


func toggle_breaker(circuit: String) -> void:
	if breakers[circuit]:
		breakers[circuit] = false
	elif breakers.values().count(true) >= POWER_CAPACITY:
		say("Sobrecarga: o gerador não aguenta mais um circuito.")
		return
	else:
		breakers[circuit] = true
	changed.emit()
