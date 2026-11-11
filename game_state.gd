extends Node
## Run-wide state shared by the puzzles: carried items, power and HUD messages.

signal toast(text: String)
signal changed
signal book_requested

const SHIPS := [
	{"call": "Marlin", "register": "café"},
	{"call": "Aurora", "register": "carvão"},
	{"call": "Gaivota", "register": "sal"},
	{"call": "Tritão", "register": "lã"},
	{"call": "Estrela do Norte", "register": "peixe"},
	{"call": "Ceres", "register": "tijolos"},
]

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
var has_flashlight := false:
	set(value):
		has_flashlight = value
		changed.emit()
var chest_opened := false
var book_read := false
var generator_started := false
var lamp_lit_once := false
var notes: Array[String] = []
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


func add_note(text: String) -> void:
	if not notes.has(text):
		notes.append(text)
		changed.emit()


## What the keeper should do next, derived from what has already happened.
func objective() -> String:
	if not chest_opened:
		return "Abra o baú aqui no píer e pegue os suprimentos."
	if not book_read:
		return "Siga a trilha até a casa do vigia, a leste, e leia o livro de registros na mesa do rádio."
	if not generator_started:
		return "Ligue o gerador no galpão, a oeste. O livro diz a ordem das válvulas."
	if not breakers.values().has(true):
		return "Ligue os disjuntores na caixa de fusíveis, dentro da casa."
	if not lamp_lit_once:
		return "Suba o farol, ao norte, e acenda a lâmpada: óleo, corda e lente, nessa ordem."
	var line := "Mantenha a luz acesa e atenda o rádio até o amanhecer."
	if oil_cans == 0:
		line += "\nSem óleo na mochila: o tambor fica no ilhéu a leste, na maré baixa."
	elif fuel_cans == 0 and not generator_on:
		line += "\nGerador parado: há combustível nos barris atrás do galpão."
	return line
