extends Node
## Run-wide state shared by the puzzles: clock, inventory, keeper status, power, radio calls
## and HUD messages.

signal toast(text: String)
signal changed
signal book_requested
signal sound(sound_name: String, position: Vector3)
signal night_ended
## A puzzle panel opened or closed; the HUD hides while any is open.
signal panel_changed(open: bool)
## Health reached 0; `cause` is the line for the dawn summary ("A sede", "O mar"...).
signal player_died(cause: String)
## The inventory asks the overlay/radio to act (flashlight toggle, open the portable radio).
signal flashlight_requested
## The flashlight beam was switched on or off (the hands animate it).
signal flashlight_toggled(on: bool)
## Something went into the inventory (the hands reach for it).
signal item_given(id: String)
signal radio_requested

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
const INVENTORY := preload("res://items/inventory.gd")
const PICKUP := preload("res://items/pickup.gd")
const SAVE := preload("res://save_game.gd")

# Keeper status (GDD 4.10), per hour of game time unless noted.
const THIRST_START := 80.0
const HUNGER_START := 60.0
const THIRST_RATE := 8.0
const HUNGER_RATE := 5.0
const THIRST_DAMAGE := 1.0 ## health per game minute at thirst 0
const HUNGER_DAMAGE := 0.3 ## health per game minute at hunger 0
const REGEN := 1.0 ## health per game minute, up to REGEN_CAP, with thirst and hunger >= 50
const REGEN_CAP := 70.0
const CRITICAL_NEED := 20.0
const CRITICAL_HEALTH := 30.0
const WATER_DAMAGE := 3.0 ## health per real second in the sea
const COLD_TIME := 60.0 ## real seconds of doubled hunger after a soaking
const COLD_FROM := 26 * 60 ## 02:00: hunger x1.5 outdoors
const HEAVY_CANS := 4 ## oil + fuel cans that stop sprinting

# Portable radio battery (GDD 4.8), per real second.
const RADIO_OPEN_DRAIN := 0.5
const RADIO_IDLE_DRAIN := 0.05
const RADIO_CHARGE := 2.0

var in_game := false
## Session setup chosen in the menu; survives `reset()`.
## Active save slot (1-3, 0 = none: editor runs and tests never touch the disk).
var save_slot := 0
## Save data to apply once main.tscn is ready ({} = fresh night).
var pending_load := {}
## Play the opening cutscene before handing over control (new game only).
var play_intro := false
var _last_hour := -1
## True while any puzzle panel (lamp console, breaker panel...) is on screen.
var panel_open := false
var _panels: Array[Object] = []
var finished := false
var minutes := float(START_MINUTES)
var inventory := INVENTORY.new()
## Counts derived from the inventory; setting them adds or removes items, so the puzzles'
## API did not change. Prefer `give()` for pickups: it reports what did not fit.
var oil_cans: int:
	get:
		return inventory.count("oil")
	set(value):
		_set_count("oil", value)
var fuel_cans: int:
	get:
		return inventory.count("fuel")
	set(value):
		_set_count("fuel", value)
var has_flashlight: bool:
	get:
		return inventory.count("flashlight") > 0
	set(value):
		_set_count("flashlight", 1 if value else 0)
## True while the flashlight beam is on (set by the overlay).
var flashlight_on := false
var has_radio: bool:
	get:
		return inventory.count("radio") > 0
var thirst := THIRST_START
var hunger := HUNGER_START
var health := 100.0
var dead := false
var death_cause := ""
## Set by the Player every physics frame.
var player: Node3D
var sprinting := false
var in_water := false
var cold_left := 0.0
var _critical := {"thirst": false, "hunger": false, "health": false}
var radio_battery := 100.0
var radio_open := false
## The portable sits in its base at the house desk (out of the inventory) while charging.
var radio_docked := false
var generator_on := false:
	set(value):
		generator_on = value
		changed.emit()
var lamp_lit := false:
	set(value):
		lamp_lit = value
		changed.emit()
## Lit, turning and reaching at least 40 %: what ships need to find the channel (set by Beacon).
var lamp_working := false:
	set(value):
		lamp_working = value
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
## True while the radio phone rings (call pending and unanswered); drives the loop and the HUD icon.
var ringing := false
var call_log: Array[String] = []
var breakers := {"radio": false, "house": false, "motor": false}


func _ready() -> void:
	_load_keepers()
	inventory.changed.connect(func() -> void: changed.emit())


func _process(delta: float) -> void:
	if not in_game or finished:
		return
	minutes += delta / SECONDS_PER_MINUTE
	if not dead:
		tick_status(delta)
	_tick_radio(delta)
	var hour := floori(minutes / 60.0)
	if hour != _last_hour:
		if _last_hour >= 0:
			autosave()
		_last_hour = hour
	if minutes >= END_MINUTES:
		minutes = END_MINUTES
		finished = true
		night_ended.emit()


func start_night() -> void:
	reset()
	if not play_intro:
		begin_play()


## Hands control to the keeper: the clock starts and the canonical first line shows.
func begin_play() -> void:
	in_game = true
	_last_hour = floori(minutes / 60.0)
	say("17:30. O sol está baixo. Você assume o Farol 7 até o amanhecer.")


func reset() -> void:
	in_game = false
	finished = false
	_panels.clear()
	panel_open = false
	_last_hour = -1
	minutes = START_MINUTES
	inventory.clear()
	thirst = THIRST_START
	hunger = HUNGER_START
	health = 100.0
	dead = false
	death_cause = ""
	sprinting = false
	flashlight_on = false
	in_water = false
	cold_left = 0.0
	_critical = {"thirst": false, "hunger": false, "health": false}
	radio_battery = 100.0
	radio_open = false
	radio_docked = false
	generator_on = false
	lamp_lit = false
	lamp_working = false
	ships_saved = 0
	ships_lost = 0
	chest_opened = false
	book_read = false
	generator_started = false
	lamp_lit_once = false
	notes.clear()
	active_call = {}
	if ringing:
		ringing = false
		play("ring_stop")
	call_log.clear()
	breakers = {"radio": false, "house": false, "motor": false}


# ---- Inventory

func _set_count(id: String, value: int) -> void:
	var diff := value - inventory.count(id)
	if diff > 0:
		give(id, diff)
	elif diff < 0:
		inventory.remove(id, -diff)


## Puts items in the inventory; whatever does not fit drops at `at` (or at the keeper's feet).
## Returns how many went into the inventory.
func give(id: String, amount: int, at := Vector3.INF) -> int:
	var rest: int = inventory.add(id, amount)
	if rest > 0:
		drop_item(id, rest, at)
		say("Inventário cheio: %s ficou no chão." % INVENTORY.item_name(id))
	if amount - rest > 0:
		item_given.emit(id)
	return amount - rest


## Spawns a pickup in the world, in front of the keeper unless `at` is given.
func drop_item(id: String, amount: int, at := Vector3.INF) -> Node3D:
	if amount <= 0:
		return null
	var host: Node = player.get_parent() if player and player.is_inside_tree() else get_tree().root
	if at == Vector3.INF:
		at = _drop_point()
	var pickup: Node3D = PICKUP.new()
	pickup.item = id
	pickup.count = amount
	host.add_child(pickup)
	pickup.global_position = at
	play("drop", at)
	return pickup


func _drop_point() -> Vector3:
	if player == null:
		return Vector3.ZERO
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	var spot := player.global_position + forward.normalized() * 0.9
	var space := player.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(spot + Vector3.UP, spot + Vector3.DOWN * 3.0, 1)
	var hit := space.intersect_ray(query)
	return hit.position if hit else spot


## Applies a consumable's effects (water, food, bandage) and spends one.
func consume(id: String) -> bool:
	var item: Dictionary = INVENTORY.ITEMS.get(id, {})
	if item.get("use", "") != "consume" or not inventory.remove(id, 1):
		return false
	var effects: Dictionary = item.effects
	thirst = clampf(thirst + effects.get("thirst", 0.0), 0.0, 100.0)
	hunger = clampf(hunger + effects.get("hunger", 0.0), 0.0, 100.0)
	health = clampf(health + effects.get("health", 0.0), 0.0, 100.0)
	play("bandage" if id == "bandage" else ("drink" if id == "water" else "eat"))
	changed.emit()
	return true


func can_sprint() -> bool:
	return thirst > 0.0 and hunger > 0.0 and oil_cans + fuel_cans < HEAVY_CANS


# ---- Keeper status

## Advances thirst, hunger and health by `delta` real seconds.
func tick_status(delta: float) -> void:
	var game_minutes := delta / SECONDS_PER_MINUTE
	var hours := game_minutes / 60.0
	thirst = maxf(thirst - THIRST_RATE * hours * (1.5 if sprinting else 1.0), 0.0)
	var hunger_mult := 1.0
	if minutes >= COLD_FROM and not is_indoors():
		hunger_mult *= 1.5
	if cold_left > 0.0:
		cold_left = maxf(cold_left - delta, 0.0)
		hunger_mult *= 2.0
	hunger = maxf(hunger - HUNGER_RATE * hours * hunger_mult, 0.0)
	if in_water:
		cold_left = COLD_TIME
		damage(WATER_DAMAGE * delta, "O mar")
	if thirst <= 0.0:
		damage(THIRST_DAMAGE * game_minutes, "A sede")
	if hunger <= 0.0:
		damage(HUNGER_DAMAGE * game_minutes, "A fome")
	if thirst >= 50.0 and hunger >= 50.0 and health < REGEN_CAP and not dead:
		health = minf(health + REGEN * game_minutes, REGEN_CAP)
	_update_critical()


## Inside the house, the shed or the lighthouse tower.
func is_indoors() -> bool:
	if player == null:
		return false
	var p := player.global_position
	var house := Rect2(24.45, 4.95, 5.6, 4.6)
	var shed := Rect2(-21.45, 12.9, 3.6, 3.6)
	var tower := Vector2(p.x, p.z).distance_to(Vector2(0.0, -12.0)) < 3.0
	return house.has_point(Vector2(p.x, p.z)) or shed.has_point(Vector2(p.x, p.z)) or tower


func damage(amount: float, cause: String) -> void:
	if dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health <= 0.0:
		die(cause)


func die(cause: String) -> void:
	if dead:
		return
	dead = true
	death_cause = cause
	_record_death()
	play("death_blow")
	player_died.emit(cause)


## Titles, the two lines on the death screen and the line the dead keeper leaves in the logbook,
## by cause. Unknown causes use "".
const FATES := {
	"A queda": {
		"title": "A RAMPA ESTAVA ESPERANDO",
		"text": "O chão chegou antes do grito.\nLá em cima, a luz continuou girando para ninguém.",
		"book": "Contei os degraus no escuro. Errei o último.",
	},
	"A sede": {
		"title": "A CISTERNA FICOU PARA TRÁS",
		"text": "O mar tem água de sobra e nenhuma serve.\nA língua foi a primeira a parar de pedir.",
		"book": "Tinha água a cem passos. Fiquei para anotar a carga.",
	},
	"A fome": {
		"title": "NINGUÉM DEIXOU PÃO NO LIVRO",
		"text": "A regra diz o que recusar, não o que comer.\nO estômago fechou antes dos olhos.",
		"book": "A despensa tinha cadeado. A fome não tem regra.",
	},
	"O mar": {
		"title": "O MAR LEVOU O DÉCIMO",
		"text": "A água não pergunta a carga. Só leva.\nOs afogados abriram espaço na fila.",
		"book": "A maré subiu mais rápido que a regra.",
	},
	"Algo na escada": {
		"title": "O NONO AINDA VIGIA",
		"text": "Na escada, passos que não eram seus.\nO farol nunca ficou sem vigia. Só trocou.",
		"book": "Alguém subiu atrás de mim. Conhecia o caminho.",
	},
}
const FATE_DEFAULT := {
	"title": "O DÉCIMO CAIU",
	"text": "O turno acabou antes da noite.\nA luz não perguntou por quê.",
	"book": "Não deu tempo de escrever.",
}
const FAILURE := {
	"title": "A LUZ NÃO CHEGOU",
	"text": "O sol voltou. As pedras já tinham dono.\nVocê sobreviveu. Eles, não.",
	"book": "Anotei todas as chamadas. Não bastou anotar.",
}

## Keepers who died, kept between attempts in user://keepers.cfg (tests point it elsewhere).
var keepers_lost := 0
var last_death := {}
var keepers_path := "user://keepers.cfg"


func fate(cause: String) -> Dictionary:
	return FATES.get(cause, FATE_DEFAULT)


## Failed dawn: the keeper lived but more ships were lost than saved.
func lighthouse_failed() -> bool:
	return ships_lost > ships_saved


## Which keeper you are: the tenth, then the eleventh...
func keeper_number() -> int:
	return 10 + keepers_lost


## The line left in the logbook by the previous keeper, or "" on the first night.
func previous_keeper_line() -> String:
	if keepers_lost <= 0:
		return ""
	var book: String = fate(last_death.get("cause", ""))["book"]
	return "VIGIA %d\n\nO vigia %d morreu às %s. A última linha dele ainda estava fresca:\n«%s»" % [
		keeper_number(), keeper_number() - 1, last_death.get("clock", "??:??"), book]


func _record_death() -> void:
	keepers_lost += 1
	last_death = {"cause": death_cause, "clock": clock_text()}
	var file := ConfigFile.new()
	file.set_value("keepers", "lost", keepers_lost)
	file.set_value("keepers", "last", last_death)
	file.save(keepers_path)


func _load_keepers() -> void:
	var file := ConfigFile.new()
	if file.load(keepers_path) == OK:
		keepers_lost = int(file.get_value("keepers", "lost", 0))
		last_death = file.get_value("keepers", "last", {})


## Statuses at or below their critical line, for the HUD icons.
func critical() -> Dictionary:
	return {
		"thirst": thirst <= CRITICAL_NEED,
		"hunger": hunger <= CRITICAL_NEED,
		"health": health <= CRITICAL_HEALTH,
	}


func _update_critical() -> void:
	var now := critical()
	for key: String in now:
		if now[key] and not _critical[key]:
			play({"thirst": "dry_throat", "hunger": "stomach", "health": "heart"}[key])
	_critical = now


# ---- Portable radio

func _tick_radio(delta: float) -> void:
	if radio_docked:
		radio_battery = minf(radio_battery + RADIO_CHARGE * delta, 100.0)
	elif has_radio:
		radio_battery = maxf(radio_battery - (RADIO_OPEN_DRAIN if radio_open else RADIO_IDLE_DRAIN) * delta, 0.0)


# ---- Saving

## Writes the active slot (lamp lit, ship resolved, every full hour, leaving to the menu).
func autosave() -> void:
	if save_slot <= 0 or not in_game or dead or player == null or not player.is_inside_tree():
		return
	SAVE.write(save_slot, player.get_parent())


func to_save() -> Dictionary:
	return {
		"minutes": minutes, "finished": finished,
		"chest_opened": chest_opened, "book_read": book_read,
		"generator_started": generator_started, "lamp_lit_once": lamp_lit_once,
		"generator_on": generator_on, "lamp_lit": lamp_lit, "lamp_working": lamp_working,
		"ships_saved": ships_saved, "ships_lost": ships_lost,
		"notes": notes.duplicate(), "call_log": call_log.duplicate(), "breakers": breakers.duplicate(),
		"slots": inventory.slots.duplicate(true), "cursor": inventory.cursor.duplicate(),
		"thirst": thirst, "hunger": hunger, "health": health, "dead": dead, "death_cause": death_cause,
		"cold_left": cold_left, "radio_battery": radio_battery, "radio_docked": radio_docked,
	}


func from_save(data: Dictionary) -> void:
	minutes = data.get("minutes", START_MINUTES)
	finished = data.get("finished", false)
	chest_opened = data.get("chest_opened", false)
	book_read = data.get("book_read", false)
	generator_started = data.get("generator_started", false)
	lamp_lit_once = data.get("lamp_lit_once", false)
	generator_on = data.get("generator_on", false)
	ships_saved = int(data.get("ships_saved", 0))
	ships_lost = int(data.get("ships_lost", 0))
	notes.assign(data.get("notes", []))
	call_log.assign(data.get("call_log", []))
	var saved_breakers: Dictionary = data.get("breakers", {})
	for circuit: String in breakers:
		breakers[circuit] = saved_breakers.get(circuit, false)
	inventory.load_slots(data.get("slots", []), data.get("cursor", {}))
	thirst = data.get("thirst", THIRST_START)
	hunger = data.get("hunger", HUNGER_START)
	health = data.get("health", 100.0)
	dead = data.get("dead", false)
	death_cause = data.get("death_cause", "")
	cold_left = data.get("cold_left", 0.0)
	radio_battery = data.get("radio_battery", 100.0)
	radio_docked = data.get("radio_docked", false)
	active_call = {}
	if ringing:
		ringing = false
		play("ring_stop")
	_last_hour = floori(minutes / 60.0)
	changed.emit()


func request_book() -> void:
	book_requested.emit()


func request_flashlight() -> void:
	flashlight_requested.emit()


func request_radio() -> void:
	radio_requested.emit()


## Panels call this when they open/close; works for any number of them.
func set_panel_open(panel: Object, open: bool) -> void:
	if open and not _panels.has(panel):
		_panels.append(panel)
	elif not open:
		_panels.erase(panel)
	var now := not _panels.is_empty()
	if now != panel_open:
		panel_open = now
		panel_changed.emit(now)


func say(text: String) -> void:
	toast.emit(text)


func play(sound_name: String, position := Vector3.INF) -> void:
	sound.emit(sound_name, position)


func clock_text() -> String:
	var of_day := int(minutes) % 1440
	return "%02d:%02d" % [floori(of_day / 60.0), of_day % 60]


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


## Flips one breaker. Returns false when a third circuit would overload the generator.
func toggle_breaker(circuit: String, at := Vector3.INF) -> bool:
	if breakers[circuit]:
		breakers[circuit] = false
	elif breakers.values().count(true) >= POWER_CAPACITY:
		play("breaker_snap", at)
		say("Sobrecarga: o gerador não aguenta mais um circuito.")
		return false
	else:
		breakers[circuit] = true
		if generator_on:
			play("breaker_buzz", at)
	play("lever", at)
	changed.emit()
	return true


func breakers_on() -> int:
	return breakers.values().count(true)


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
		return "Suba o farol, ao norte, e acenda a lâmpada no console: pressão e calor no verde, abra a válvula e dê corda."
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
