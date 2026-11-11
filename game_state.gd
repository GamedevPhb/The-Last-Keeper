extends Node
## Run-wide state shared by the puzzles: clock, carried items, power, radio calls and HUD messages.

signal toast(text: String)
signal changed
signal book_requested
signal sound(sound_name: String, position: Vector3)
signal night_ended

const SHIPS := [
	{"call": "Marlin", "register": "café"},
	{"call": "Aurora", "register": "carvão"},
	{"call": "Gaivota", "register": "sal"},
	{"call": "Tritão", "register": "lã"},
	{"call": "Estrela do Norte", "register": "peixe"},
	{"call": "Ceres", "register": "tijolos"},
]

## The night runs from 17:30 to 06:00 of the next day, in minutes since midnight.
const START_MINUTES := 17 * 60 + 30
const END_MINUTES := 30 * 60
const SECONDS_PER_MINUTE := 1.2
## How many circuits the generator can feed at once.
const POWER_CAPACITY := 2
const OIL_DRUM := Vector3(51.6, 0.0, -2.3)

var in_game := false
var finished := false
var minutes := float(START_MINUTES)
var oil_cans := 0:
	set(value):
		oil_cans = value
		changed.emit()
var fuel_cans := 0:
	set(value):
		fuel_cans = value
		changed.emit()
var has_flashlight := false:
	set(value):
		has_flashlight = value
		changed.emit()
var generator_on := false:
	set(value):
		generator_on = value
		changed.emit()
var lamp_lit := false:
	set(value):
		lamp_lit = value
		changed.emit()
var ships_saved := 0:
	set(value):
		ships_saved = value
		changed.emit()
var ships_lost := 0:
	set(value):
		ships_lost = value
		changed.emit()
var chest_opened := false
var book_read := false
var generator_started := false
var lamp_lit_once := false
var notes: Array[String] = []
## The radio call in progress: {call, claim, status ("incoming" or "contact"), left}.
var active_call := {}
var call_log: Array[String] = []
var breakers := {"radio": false, "house": false, "motor": false}


func _process(delta: float) -> void:
	if not in_game or finished:
		return
	minutes += delta / SECONDS_PER_MINUTE
	if minutes >= END_MINUTES:
		minutes = END_MINUTES
		finished = true
		night_ended.emit()


func start_night() -> void:
	reset()
	in_game = true
	say("17:30. O sol está baixo. Você assume o Farol 7 até o amanhecer.")


func reset() -> void:
	in_game = false
	finished = false
	minutes = START_MINUTES
	oil_cans = 0
	fuel_cans = 0
	has_flashlight = false
	generator_on = false
	lamp_lit = false
	ships_saved = 0
	ships_lost = 0
	chest_opened = false
	book_read = false
	generator_started = false
	lamp_lit_once = false
	notes.clear()
	active_call = {}
	call_log.clear()
	breakers = {"radio": false, "house": false, "motor": false}


func say(text: String) -> void:
	toast.emit(text)


func play(sound_name: String, position := Vector3.INF) -> void:
	sound.emit(sound_name, position)


func clock_text() -> String:
	var of_day := int(minutes) % 1440
	return "%02d:%02d" % [of_day / 60, of_day % 60]


## 0 at dusk, 1 at dawn. Drives how hard the night pushes back.
func progress() -> float:
	return clampf((minutes - START_MINUTES) / float(END_MINUTES - START_MINUTES), 0.0, 1.0)


## 0 to 1: how tense the moment is, for the music.
func tension() -> float:
	if not in_game:
		return 0.12
	var value := progress() * 0.65 + minf(ships_lost * 0.08, 0.25)
	if not active_call.is_empty():
		value += 0.08
	if not lamp_lit and minutes > 19 * 60:
		value += 0.1
	return clampf(value, 0.0, 1.0)


func log_call(text: String) -> void:
	call_log.push_front(text)
	if call_log.size() > 6:
		call_log.pop_back()
	changed.emit()


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
	play("switch")
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
		return "Ligue o gerador no galpão, a oeste: abasteça o tanque e abra as válvulas na ordem do livro."
	if not breakers.values().has(true):
		return "Ligue os disjuntores na caixa de fusíveis, dentro da casa."
	if not lamp_lit_once:
		if oil_cans == 0:
			return "Sem óleo! O tambor fica no ilhéu a leste: cruze as pedras na maré baixa."
		return "Suba o farol, ao norte, e acenda a lâmpada: óleo, corda e lente, nessa ordem."
	var line := "Mantenha a luz acesa e atenda o rádio até as 06:00."
	if oil_cans == 0:
		line += "\nSem óleo na mochila: o tambor fica no ilhéu a leste, na maré baixa."
	elif fuel_cans == 0 and not generator_on:
		line += "\nGerador parado: há combustível nos barris atrás do galpão."
	return line


## Where the current objective is, or Vector3.INF when there is nothing to point at.
func objective_target() -> Vector3:
	if not chest_opened:
		return Vector3(-0.7, 0.0, 47.2)
	if not book_read:
		return Vector3(25.85, 0.0, 5.6)
	if not generator_started:
		return Vector3(-20.0, 0.0, 14.7)
	if not breakers.values().has(true):
		return Vector3(28.5, 0.0, 5.1)
	if oil_cans == 0 and not lamp_lit:
		return OIL_DRUM
	if not lamp_lit_once:
		return Vector3(0.0, 0.0, -12.0)
	return Vector3.INF
