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
## A story scene is due (`ui/story_scene.gd`, id in its SCENES table); the overlay plays it.
signal scene_requested(id: String)
## The flashlight beam was switched on or off (the hands animate it).
signal flashlight_toggled(on: bool)
## Something went into the inventory (the hands reach for it).
signal item_given(id: String)
signal radio_requested
## The weapon in hand changed (or its magazine did): viewmodel and HUD redraw.
signal weapon_changed
## Screen impact: a white flash and/or a camera shake (amplitude in meters of view offset).
signal impact(flash: bool, shake: float)
## A loud action (a shot, a swing) at a point; `radius` is how far it carries (enemies listen).
signal noise_made(position: Vector3, radius: float)
## A radio call was settled: outcome is "docked", "liar", "refused" or "wrecked" (the ships act it out).
signal ship_event(ship: String, outcome: String)

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
const WEAPON_DEFS := preload("res://items/weapon_defs.gd")
const PORTINHO_HINTS := preload("res://puzzles/portinho_hints.gd")

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
## Which night of the run this is (1 = the guided, gentler one); saved, survives `advance_night()`.
var night := 1
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
## True while a story scene plays: the night clock, status and radio wait for it.
var scene_active := false
## Weapon in hand ("" = bare hands) and the rounds loaded in each firearm's magazine.
var equipped := ""
const EMERGE_RANGE := 45.0
var _last_impact := -100.0
var mags := {"pistol": 0, "shotgun": 0}
var scenes_seen := {}
## Portinho easter egg: sweeps of the beam over the giant (3 solve it), solved, crate pickups spawned, doll taken.
const PORTINHO_SWEEPS := 3
const PORTINHO_POINT := Vector3(56.0, 13.0, -51.0)
## Where each hint context lives (XZ); the keeper's nearest one within PORTINHO_NEAR wins, else "idle".
const PORTINHO_SPOTS := {
	"lamp": Vector3(0.0, 0.0, -12.0), "generator": Vector3(-20.4, 0.0, 14.7), "fuses": Vector3(28.5, 0.0, 5.1),
	"oil_factory": Vector3(-12.0, 0.0, 21.5), "fuel_factory": Vector3(-8.5, 0.0, 21.5),
	"radio": Vector3(25.25, 0.0, 5.4), "fishing": Vector3(7.0, 0.0, -55.0), "workshop": Vector3(-27.0, 0.0, 8.0),
	"garden": Vector3(22.0, 0.0, 18.0), "watchtower": Vector3(-67.0, 0.0, -19.0), "fence": Vector3(27.0, 0.0, 7.0),
}
const PORTINHO_NEAR := 7.0
var portinho_sweeps := 0
var portinho_solved := false
var portinho_crate_given := false
var portinho_doll_taken := false
var portinho_hinted := false
var _portinho_reach_said := false
var _portinho_last := ""
var _scene_hold := {}
## Flashlight charge, 0-100. Drains while the beam is on; a battery adds BATTERY_CHARGE.
var flashlight_battery := 100.0
## Real seconds left of the lens-cleaner boost (stronger, longer beam); ends early with a dead battery.
var lens_left := 0.0
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
## The tide's invasion (`world/invasion.gd`, GDD 4.11): running, finished, wave (0 = warning,
## 1-3), foes left, kills, rounds spent and whether the resupply crate has been given.
var invasion_active := false
var invasion_done := false
var invasion_wave := 0
var invasion_left := 0
var invasion_kills := 0
var invasion_spent := 0
var invasion_crate := false
## Fence/door reinforcement level (0-2, `puzzles/fence.gd`): lasts the whole run, slows and thins the waves.
var fence_level := 0


## Night from which each structure / activity exists. The only table with night numbers.
## "gather_basic" = wood, algae and fat (feed the night-1 factories); "gather" = coal and scrap.
const UNLOCKS := {"oil_factory": 1, "fuel_factory": 1, "gather_basic": 1, "gather": 2, "fishing": 2, "workshop": 2,
	"cistern": 3, "garden": 3, "watchtower": 3, "fortify": 3}

## Story scenes: fire once each (saved in `scenes_seen`). "cond" is a state that must hold for
## "delay" seconds; "at" is a clock time in minutes (a scene missed by 10+ minutes is dropped);
## "near" is [center, radius] in XZ around the keeper, held for "delay" seconds, and an optional
## "unlock" (a UNLOCKS id) keeps it from firing before that night. `tut_*` scenes are never erased
## by `advance_night()`, so each plays once per game.
const SCENE_TRIGGERS := {
	"house": {"cond": "house", "delay": 0.8},
	"lamp": {"cond": "lamp", "delay": 1.5},
	"bell": {"at": 23.0 * 60.0 + 45.0},
	"lavado": {"at": 24.0 * 60.0},
	"captain": {"at": 27.0 * 60.0 + 5.0},
	"portinho": {"at": 21.0 * 60.0 + 45.0, "night": 1}, ## the giant Portinho waves from the horizon (night 1 only)
	"tut_lamp": {"near": [Vector3(0.0, 0.0, -12.0), 7.0], "delay": 0.6},
	"tut_generator": {"near": [Vector3(-20.4, 0.9, 14.7), 5.0], "delay": 0.6},
	"tut_oil_factory": {"near": [Vector3(-12.0, 0.0, 21.5), 5.0], "delay": 0.6, "unlock": "oil_factory"},
	"tut_fuel_factory": {"near": [Vector3(-8.5, 0.0, 21.5), 5.0], "delay": 0.6, "unlock": "fuel_factory"},
	"tut_fishing": {"near": [Vector3(7.0, 0.0, -55.0), 5.0], "delay": 0.6, "unlock": "fishing"},
	"tut_workshop": {"near": [Vector3(-27.0, 0.0, 8.0), 5.0], "delay": 0.6, "unlock": "workshop"},
	"tut_garden": {"near": [Vector3(22.0, 0.0, 18.0), 5.0], "delay": 0.6, "unlock": "garden"},
	"tut_watchtower": {"near": [Vector3(-67.0, 0.0, -19.0), 5.0], "delay": 0.6, "unlock": "watchtower"},
	"tut_fence": {"near": [Vector3(27.0, 0.0, 7.0), 5.0], "delay": 0.6, "unlock": "fortify"},
	"tut_cave": {"near": [Vector3(31.0, 0.0, -60.0), 6.0], "delay": 0.6, "unlock": "gather"},
	"aurora": {"event": ["Aurora", ["liar", "docked"]]}, ## the Aurora authorized, honest or lying (radio.gd, ship_event)
}
## Night 1 is the tutorial: consumption and wear at a fraction; from night 2 it is the full 1.0 and grows.
const NIGHT_ONE_FACTOR := 0.55
const NIGHT_GROWTH := 0.15
const NIGHT_MAX_FACTOR := 1.6
const FLASH_DRAIN := 100.0 / 150.0 ## full charge = 150 s of beam (night 2+; night 1 lasts twice as long)
const BATTERY_CHARGE := 50.0
const LENS_TIME := 90.0 ## about 75 game minutes
const FLASH_LOW := 20.0 ## below this the beam dims and flickers


func _ready() -> void:
	_load_keepers()
	inventory.changed.connect(func() -> void: changed.emit())
	ship_event.connect(_on_ship_event)


func _process(delta: float) -> void:
	if not in_game or finished or scene_active:
		return
	_check_scenes(delta)
	_portinho_tick()
	minutes += delta / SECONDS_PER_MINUTE
	if not dead:
		tick_status(delta)
	_tick_flashlight(delta)
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
	night = 1
	in_game = false
	finished = false
	_panels.clear()
	panel_open = false
	_last_hour = -1
	minutes = START_MINUTES
	inventory.clear()
	equipped = ""
	mags = {"pistol": 0, "shotgun": 0}
	thirst = THIRST_START
	hunger = HUNGER_START
	health = 100.0
	dead = false
	death_cause = ""
	sprinting = false
	flashlight_on = false
	flashlight_battery = 100.0
	lens_left = 0.0
	scene_active = false
	scenes_seen = {}
	portinho_sweeps = 0
	portinho_solved = false
	portinho_crate_given = false
	portinho_doll_taken = false
	portinho_hinted = false
	_portinho_reach_said = false
	_scene_hold = {}
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
	invasion_active = false
	invasion_done = false
	invasion_wave = 0
	invasion_left = 0
	invasion_kills = 0
	invasion_spent = 0
	invasion_crate = false
	fence_level = 0


# ---- Weapons

## Puts a weapon in hand ("" = holster). False if it is not in the inventory.
func equip(id: String) -> bool:
	if id != "" and (not WEAPON_DEFS.is_weapon(id) or inventory.count(id) <= 0):
		return false
	if id == equipped:
		return true
	equipped = id
	if id != "":
		say("%s na mão." % INVENTORY.item_name(id))
	weapon_changed.emit()
	return true


## Cycles bare hands -> axe -> pistol -> shotgun over what the keeper carries.
func cycle_weapon() -> void:
	var owned: Array[String] = [""]
	for id: String in WEAPON_DEFS.ORDER:
		if inventory.count(id) > 0:
			owned.append(id)
	equip(owned[(owned.find(equipped) + 1) % owned.size()])


## Rounds of the equipped firearm's ammo still in the inventory (0 for the axe / bare hands).
func reserve_ammo(id := "") -> int:
	var def: Dictionary = WEAPON_DEFS.get_def(equipped if id == "" else id)
	return inventory.count(def.ammo) if def.get("ranged", false) else 0


## Fires a flash/shake (`ui/impact.gd`). A `cooldown` > 0 drops it if one fired that recently.
func impact_fx(flash := true, shake := 0.02, cooldown := 0.0) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_impact < cooldown:
		return false
	_last_impact = now
	impact.emit(flash, shake)
	return true


## An enemy surfaces: impact only if it appears within sight range of the keeper (1.5 s apart).
func enemy_emerged(at: Vector3) -> bool:
	if player == null or player.global_position.distance_to(at) > EMERGE_RANGE:
		return false
	return impact_fx(true, 0.025, 1.5)


func make_noise(at: Vector3, radius: float) -> void:
	noise_made.emit(at, radius)


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


## Fires the next due story scene (one at a time, never over a panel or after death).
func _check_scenes(delta: float) -> void:
	if panel_open or dead:
		return
	for id: String in SCENE_TRIGGERS:
		if scenes_seen.get(id, false):
			continue
		var trigger: Dictionary = SCENE_TRIGGERS[id]
		if trigger.has("event") or (trigger.has("night") and night != int(trigger.night)):
			continue
		var due := false
		if trigger.has("at"):
			if minutes >= trigger.at + 10.0:
				scenes_seen[id] = true # slept through it (a loaded game, a long panel)
			due = minutes >= trigger.at
		elif trigger.has("near"):
			var holds := false
			if player and player.is_inside_tree() and (not trigger.has("unlock") or unlocked(trigger.unlock)):
				var center: Vector3 = trigger.near[0]
				var here: Vector3 = player.global_position
				holds = Vector2(here.x - center.x, here.z - center.z).length() <= float(trigger.near[1])
			_scene_hold[id] = _scene_hold.get(id, 0.0) + delta if holds else 0.0
			due = _scene_hold[id] >= trigger.delay
		else:
			var holds: bool = in_house() if trigger.cond == "house" else lamp_lit_once
			_scene_hold[id] = _scene_hold.get(id, 0.0) + delta if holds else 0.0
			due = _scene_hold[id] >= trigger.delay
		if due and not scenes_seen.get(id, false):
			play_scene(id)
			return


## Event-driven scenes: once per game, after the ship has begun its verdict.
func _on_ship_event(ship: String, outcome: String) -> void:
	for id: String in SCENE_TRIGGERS:
		var event: Array = SCENE_TRIGGERS[id].get("event", [])
		if event.size() == 2 and event[0] == ship and outcome in event[1] and not scenes_seen.get(id, false) and in_game:
			scenes_seen[id] = true
			scene_requested.emit.call_deferred(id)


## The giant Portinho stands on the horizon: night 1, after he appeared and until the beam solves it.
func portinho_active() -> bool:
	return night <= 1 and scenes_seen.get("portinho", false) and not portinho_solved


## One-time nudge when he appears and the lighthouse is dark.
func _portinho_tick() -> void:
	if portinho_active() and not portinho_hinted and not panel_open:
		portinho_hinted = true
		if not lamp_working:
			say("Alguém acena no horizonte. Acenda o farol.")


## The beam has just started covering the giant. It counts only with the lamp working and the
## reach (`reaches`) long enough; otherwise says once that the light falls short. Returns true if it counted.
func portinho_sweep(lamp_ok: bool, reaches: bool) -> bool:
	if not portinho_active():
		return false
	if not reaches:
		if not _portinho_reach_said:
			_portinho_reach_said = true
			say("A luz não chega lá.")
		return false
	if not lamp_ok:
		return false
	portinho_sweeps += 1
	play("lamp_valve")
	if portinho_sweeps >= PORTINHO_SWEEPS:
		portinho_solved = true
		play_scene("portinho_friend")
	else:
		say("O gigante responde ao feixe (%d/%d)." % [portinho_sweeps, PORTINHO_SWEEPS])
	return true


## True once the tin doll sits on the radio desk (the lore note was found).
func portinho_doll_present() -> bool:
	return scenes_seen.get("portinho_friend", false) and not portinho_doll_taken


## Hint context for a keeper position: the nearest station within PORTINHO_NEAR, else "idle".
func portinho_context(at: Vector3) -> String:
	var best := "idle"
	var best_distance := PORTINHO_NEAR
	for key: String in PORTINHO_SPOTS:
		var spot: Vector3 = PORTINHO_SPOTS[key]
		var distance := Vector2(at.x - spot.x, at.z - spot.z).length()
		if distance < best_distance:
			best_distance = distance
			best = key
	return best


## Says a hint line for where the keeper is, never the same line twice in a row.
func portinho_hint(at := Vector3.INF) -> String:
	if at == Vector3.INF:
		at = player.global_position if player and player.is_inside_tree() else Vector3(1000, 0, 1000)
	var lines: Array = PORTINHO_HINTS.HINTS[portinho_context(at)]
	var line: String = lines.pick_random()
	for i in 6:
		if line != _portinho_last or lines.size() < 2:
			break
		line = lines.pick_random()
	_portinho_last = line
	say(line)
	return line


## Marks a story scene seen and asks the overlay to play it.
func play_scene(id: String) -> void:
	scenes_seen[id] = true
	scene_requested.emit(id)


## Flashlight drain while on; the lens boost counts down and dies with the battery.
func _tick_flashlight(delta: float) -> void:
	if flashlight_on:
		flashlight_battery = maxf(flashlight_battery - FLASH_DRAIN * (0.5 if night <= 1 else 1.0) * delta, 0.0)
	if lens_left > 0.0:
		lens_left = 0.0 if flashlight_battery <= 0.0 else maxf(lens_left - delta, 0.0)


## Charges the flashlight with a battery from the inventory. False (nothing spent) if it is already full.
func use_battery() -> bool:
	if flashlight_battery >= 99.5:
		say("A lanterna já está com a pilha cheia.")
		return false
	if not inventory.remove("battery", 1):
		return false
	flashlight_battery = minf(flashlight_battery + BATTERY_CHARGE, 100.0)
	play("switch")
	say("Pilha nova na lanterna: %d%%." % roundi(flashlight_battery))
	changed.emit()
	return true


## Wipes the lens: the beam is 1.5x stronger and reaches farther for LENS_TIME or until the battery dies.
func use_lens_cleaner() -> bool:
	if not has_flashlight:
		say("Você não tem lanterna para limpar.")
		return false
	if lens_left > 0.0:
		say("A lente ainda está limpa.")
		return false
	if not inventory.remove("lens_cleaner", 1):
		return false
	lens_left = LENS_TIME
	play("paper")
	say("Lente limpa: a luz da lanterna ficou mais forte e alcança mais longe.")
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
func in_house() -> bool:
	if player == null:
		return false
	return Rect2(24.45, 4.95, 5.6, 4.6).has_point(Vector2(player.global_position.x, player.global_position.z))


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
		"minutes": minutes, "finished": finished, "night": night,
		"chest_opened": chest_opened, "book_read": book_read,
		"generator_started": generator_started, "lamp_lit_once": lamp_lit_once,
		"generator_on": generator_on, "lamp_lit": lamp_lit, "lamp_working": lamp_working,
		"ships_saved": ships_saved, "ships_lost": ships_lost,
		"notes": notes.duplicate(), "call_log": call_log.duplicate(), "breakers": breakers.duplicate(),
		"slots": inventory.slots.duplicate(true), "cursor": inventory.cursor.duplicate(),
		"thirst": thirst, "hunger": hunger, "health": health, "dead": dead, "death_cause": death_cause,
		"scenes_seen": scenes_seen.duplicate(), "flashlight_battery": flashlight_battery, "lens_left": lens_left,
		"cold_left": cold_left, "radio_battery": radio_battery, "radio_docked": radio_docked,
		"equipped": equipped, "mags": mags.duplicate(),
		"invasion_active": invasion_active, "invasion_done": invasion_done, "invasion_wave": invasion_wave,
		"invasion_kills": invasion_kills, "invasion_spent": invasion_spent, "invasion_crate": invasion_crate,
		"fence_level": fence_level,
		"portinho": {"sweeps": portinho_sweeps, "solved": portinho_solved, "crate": portinho_crate_given,
			"doll": portinho_doll_taken, "hinted": portinho_hinted},
	}


func from_save(data: Dictionary) -> void:
	minutes = data.get("minutes", START_MINUTES)
	night = maxi(int(data.get("night", 1)), 1)
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
	var saved_mags: Dictionary = data.get("mags", {})
	for firearm: String in mags:
		mags[firearm] = int(saved_mags.get(firearm, 0))
	invasion_active = data.get("invasion_active", false)
	invasion_done = data.get("invasion_done", false)
	invasion_wave = int(data.get("invasion_wave", 0))
	invasion_kills = int(data.get("invasion_kills", 0))
	invasion_spent = int(data.get("invasion_spent", 0))
	invasion_crate = data.get("invasion_crate", false)
	fence_level = int(data.get("fence_level", 0))
	var saved_portinho: Dictionary = data.get("portinho", {})
	portinho_sweeps = int(saved_portinho.get("sweeps", 0))
	portinho_solved = saved_portinho.get("solved", false)
	portinho_crate_given = saved_portinho.get("crate", false)
	portinho_doll_taken = saved_portinho.get("doll", false)
	portinho_hinted = saved_portinho.get("hinted", false)
	_portinho_reach_said = false
	invasion_left = 0
	equipped = str(data.get("equipped", ""))
	if equipped != "" and inventory.count(equipped) <= 0:
		equipped = ""
	weapon_changed.emit()
	thirst = data.get("thirst", THIRST_START)
	hunger = data.get("hunger", HUNGER_START)
	health = data.get("health", 100.0)
	dead = data.get("dead", false)
	death_cause = data.get("death_cause", "")
	cold_left = data.get("cold_left", 0.0)
	scenes_seen = data.get("scenes_seen", {}).duplicate()
	if lamp_lit_once:
		scenes_seen["lamp"] = true # an old save: the lamp is already burning
	scene_active = false
	_scene_hold = {}
	flashlight_battery = data.get("flashlight_battery", 100.0)
	lens_left = data.get("lens_left", 0.0)
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
## Whether a structure / activity of the `UNLOCKS` table exists on the current night.
func unlocked(id: String) -> bool:
	return night >= int(UNLOCKS.get(id, 1))


func progress() -> float:
	var base := (minutes - START_MINUTES) / float(END_MINUTES - START_MINUTES)
	return clampf(base + (0.04 if invasion_done else 0.0), 0.0, 1.0) # the tide left the island uneasy


## Multiplier on oil / fuel use and on the lamp's wear (pressure, temperature, spring, gusts).
func night_factor() -> float:
	if night <= 1:
		return NIGHT_ONE_FACTOR
	return minf(1.0 + NIGHT_GROWTH * (night - 2), NIGHT_MAX_FACTOR)


## Night 1 is the guided one: no lying ships before midnight, a friendlier first call and the tutorial objectives.
func tutorial() -> bool:
	return night <= 1


## Moves the run to the next night: keeps the bag, the notes, the book and the story seen, and
## resets the clock, needs and every station (the island itself reloads with the scene).
func advance_night() -> void:
	night += 1
	if radio_docked:
		radio_docked = false
		inventory.add("radio", 1)
	minutes = START_MINUTES
	finished = false
	thirst = THIRST_START
	hunger = HUNGER_START
	health = 100.0
	dead = false
	death_cause = ""
	flashlight_on = false
	flashlight_battery = 100.0
	lens_left = 0.0
	cold_left = 0.0
	radio_battery = 100.0
	radio_open = false
	generator_on = false
	lamp_lit = false
	lamp_working = false
	ships_saved = 0
	ships_lost = 0
	chest_opened = false
	generator_started = false
	lamp_lit_once = false
	call_log.clear()
	active_call = {}
	breakers = {"radio": false, "house": false, "motor": false}
	invasion_active = false
	invasion_done = false
	invasion_wave = 0
	invasion_left = 0
	invasion_kills = 0
	invasion_spent = 0
	invasion_crate = false
	for id: String in ["bell", "lavado", "captain", "aurora"]:
		scenes_seen.erase(id)
	scene_active = false
	_scene_hold = {}
	_last_hour = -1


## Save data for the start of the current night (after `advance_night`): GameState only, the
## island rebuilds fresh. Written to the slot so "Continuar" in the menu resumes here.
func night_start_data() -> Dictionary:
	return {
		"version": SAVE.VERSION,
		"meta": {"minutes": minutes, "clock": clock_text(), "night": night, "lamp": "APAGADA", "finished": false,
			"saved_at": Time.get_datetime_string_from_system(false, true)},
		"state": to_save(), "nodes": {}, "pickups": [],
	}


## 0 to 1: how tense the moment is, for the music.
func tension() -> float:
	if not in_game:
		return 0.12
	var value := progress() * 0.65 + minf(ships_lost * 0.08, 0.25)
	if invasion_active:
		value += 0.2 + 0.05 * invasion_wave
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


## One line for the dawn summary about the invasion ("" if it never came).
func invasion_summary() -> String:
	if not invasion_done and not invasion_active:
		return ""
	var line := "A maré: %d afogados abatidos" % invasion_kills
	if invasion_spent > 0:
		line += ", %d tiros gastos" % invasion_spent
	return line + (". A maré recuou." if invasion_done else ". Ela não recuou.")


## Firearm rounds the keeper holds (magazines plus spare ammo), for counting what was spent.
func rounds_total() -> int:
	return int(mags.pistol) + int(mags.shotgun) + inventory.count("ammo_pistol") + inventory.count("shells")


## The three inscriptions around the island that spell the cellar padlock (puzzles/cellar_lock.gd, 8-3-5).
const CODE_CLUES := ["OITO vigias", "LOTE 3", "CAPACIDADE 5"]
const CODE_NOTE := "Cadeado do porão, somando as pistas: OITO vigias, LOTE 3, CAPACIDADE 5. O código deve ser 8 - 3 - 5."


func add_note(text: String) -> void:
	if not notes.has(text):
		notes.append(text)
		if not notes.has(CODE_NOTE) and CODE_CLUES.all(func(clue: String) -> bool: return notes.any(func(note: String) -> bool: return clue in note)):
			notes.append(CODE_NOTE)
			say("Anotado no livro: o código do cadeado do porão (8 - 3 - 5).")
		changed.emit()


## What the keeper should do next, derived from what has already happened.
func objective() -> String:
	var text := _base_objective()
	if portinho_active() and lamp_lit_once:
		text += "\nUm farol gigante acena no horizonte a nordeste: varra-o com o feixe da lâmpada (%d/%d)." % [portinho_sweeps, PORTINHO_SWEEPS]
	return text


func _base_objective() -> String:
	if not chest_opened:
		return "Abra o baú aqui no píer e pegue os suprimentos."
	if not book_read:
		return "Siga a trilha até a casa do vigia, a leste. Na mesa do rádio, leia o livro de registros (E)."
	if not generator_started:
		return "Ligue o gerador no galpão, a oeste: abasteça o tanque com combustível e abra as válvulas na ordem do livro."
	if not breakers.values().has(true):
		return "Ligue os disjuntores na caixa de fusíveis, dentro da casa. O gerador aguenta só dois."
	if not lamp_lit_once:
		if oil_cans == 0:
			return "Sem óleo! O tambor fica no ilhéu a leste: cruze as pedras na maré baixa."
		return "Suba o farol, ao norte, e use o console da lâmpada:\n1) abasteça o óleo; 2) segure AQUECER e bombeie até temperatura e pressão ficarem NO VERDE; 3) só então abra a válvula (frio afoga!); 4) dê corda no ritmo."
	if tutorial() and ships_saved + ships_lost == 0:
		return "Lâmpada acesa! Agora atenda o rádio na casa: sintonize, compare a carga com o livro (J) e autorize ou recuse."
	var line := "Mantenha a luz acesa e atenda o rádio até as 06:00."
	if oil_cans == 0:
		line += "\nSem óleo na mochila: o tambor fica no ilhéu a leste, na maré baixa."
	elif fuel_cans == 0 and not generator_on:
		line += "\nGerador parado: há combustível nos barris atrás do galpão."
	if tutorial() and generator_started and unlocked("oil_factory"):
		line += "\nDica: as fábricas, perto do galpão, viram lenha, gordura e algas em óleo, e lenha, carvão e restos em combustível."
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
