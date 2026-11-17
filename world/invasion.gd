extends Node3D
## The tide's invasion (GDD 4.11): from 02:30 the drowned come out of the south beach in three
## growing waves (4, 6, 8; the last carries one tougher Lavado) and hunt the keeper. A warning
## (bell, horn, message, a resupply of ammunition in the watchman's house) comes first, and a
## short rest lets the keeper reload between waves. The lamp's beam still freezes them. Spawning
## and walking belong to `lavados.gd` (`spawn_foe`); the phase lives in `GameState.invasion_*`
## so it is saved. Loading mid-wave restarts that wave.

const TRIGGER := 26.0 * 60.0 + 30.0 ## 02:30
const LATEST := 29.0 * 60.0 + 30.0 ## 05:30: the tide ebbs by itself at first light
const WAVES := [4, 6, 8] ## night 2; see `waves()`
const LEAD := 12.0 ## real seconds from the warning to the first wave
const FENCE_LEAD := 8.0 ## extra real seconds of warning per fence level
const FENCE_CUT := 1 ## foes fewer per wave per fence level (never under 2)
const REST := 10.0 ## real seconds of rest after a cleared wave
const FORCE := 40.0 ## a wave that lingers this long (real s) is followed by the next anyway
const SPAWN_GAP := 0.45
const MODELS := ["Character_Killer_01", "Character_Killer_02", "Character_Killer_03", "Character_Killer_04"]
const TOUGH_MODEL := "Character_Killer_05"
const TOUGH_HP := 2.2 ## night 1: 1.4
const TOUGH_SPEED := 1.3
const BEACH := [Vector3(-14.0, 0.0, 33.0), Vector3(10.0, 0.0, 30.0), Vector3(-5.0, 0.0, 37.0),
	Vector3(18.0, 0.0, 25.0), Vector3(-22.0, 0.0, 28.0), Vector3(3.0, 0.0, 41.0)]
const CRATE_AT := Vector3(27.2, 0.0, 6.4) ## in front of the house cupboard
const CRATE := [["ammo_pistol", 12], ["shells", 4]]

var _lavados: Node3D
var _foes: Array[Node3D] = []
var _queue: Array = [] ## foes of the wave still to come ashore: [model, tough]
var _spawn_cd := 0.0
var _lead := LEAD
var _rest := 0.0
var _since_wave := 0.0
var _wave_live := false
var _last_rounds := -1
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_lavados = get_parent().get_node_or_null("Lavados")


## Foes per wave: 3-4-5 on the tutorial night, 4-6-8 on night 2, two more per wave for each night after.
func waves() -> Array:
	var cut := FENCE_CUT * GameState.fence_level
	if GameState.tutorial():
		return [maxi(3 - cut, 2), maxi(4 - cut, 2), maxi(5 - cut, 2)]
	var extra := 2 * mini(GameState.night - 2, 3)
	return [maxi(WAVES[0] + extra - cut, 2), maxi(WAVES[1] + extra - cut, 2), maxi(WAVES[2] + extra - cut, 2)]


func foes() -> Array[Node3D]:
	return _foes


func _physics_process(delta: float) -> void:
	if not GameState.in_game or GameState.dead or GameState.finished or GameState.scene_active or _lavados == null:
		return
	if GameState.invasion_done:
		return
	if not GameState.invasion_active:
		if GameState.minutes >= TRIGGER and GameState.minutes < LATEST:
			_begin()
		return
	if GameState.minutes >= LATEST:
		_finish(false)
		return
	_count_shots()
	_foes.assign(_foes.filter(func(foe: Node3D) -> bool: return is_instance_valid(foe) and not foe.dead))
	GameState.invasion_left = _foes.size() + _queue.size()
	if GameState.invasion_wave == 0:
		_lead -= delta
		if _lead <= 0.0:
			_start_wave(1)
		return
	if not _wave_live: # loaded in the middle of a wave: bring it again
		_start_wave(GameState.invasion_wave)
		return
	_release(delta)
	_since_wave += delta
	if GameState.invasion_left > 0:
		if _since_wave > FORCE and GameState.invasion_wave < WAVES.size():
			_start_wave(GameState.invasion_wave + 1)
		return
	if GameState.invasion_wave >= WAVES.size():
		_finish(true)
		return
	if _rest <= 0.0:
		_rest = REST
		GameState.say("Onda %d vencida. Recarregue." % GameState.invasion_wave)
	_rest -= delta
	if _rest <= 0.0:
		_rest = 0.0
		_start_wave(GameState.invasion_wave + 1)


func _begin() -> void:
	GameState.invasion_active = true
	GameState.invasion_wave = 0
	_lead = LEAD + FENCE_LEAD * GameState.fence_level
	_last_rounds = GameState.rounds_total()
	GameState.play("bell")
	GameState.play("horn")
	GameState.impact_fx(true, 0.03)
	GameState.add_note("02:30. O mar devolveu algo: os afogados saem da praia sul, aos montes. Atire neles; o barulho os chama.")
	if not GameState.invasion_crate:
		GameState.invasion_crate = true
		_drop_crate()
		GameState.say("O mar devolveu algo. Há munição na casa do vigia.")
	else:
		GameState.say("O mar devolveu algo.")


func _start_wave(number: int) -> void:
	GameState.invasion_wave = number
	_wave_live = true
	_since_wave = 0.0
	_rest = 0.0
	_queue.clear()
	var count: int = waves()[number - 1]
	for i in count:
		_queue.append([MODELS[_rng.randi() % MODELS.size()], number == WAVES.size() and i == count - 1])
	GameState.say("Onda %d de %d. Eles vêm da praia." % [number, WAVES.size()])
	GameState.play("horn")
	GameState.changed.emit()


## Brings the queued foes ashore one by one.
func _release(delta: float) -> void:
	if _queue.is_empty():
		return
	_spawn_cd -= delta
	if _spawn_cd > 0.0:
		return
	_spawn_cd = SPAWN_GAP
	var entry: Array = _queue.pop_front()
	var spot: Vector3 = BEACH[_rng.randi() % BEACH.size()] + Vector3(_rng.randf_range(-2.0, 2.0), 0.0, _rng.randf_range(-1.5, 1.5))
	var foe: Node3D
	if entry[1]:
		foe = _lavados.spawn_foe(TOUGH_MODEL, spot, true, TOUGH_HP if not GameState.tutorial() else 1.4, TOUGH_SPEED, Color(0.8, 0.5, 0.55))
	else:
		foe = _lavados.spawn_foe(entry[0], spot, true, 1.0, _rng.randf_range(0.9, 1.15))
	foe.died.connect(func(_dead: Node3D) -> void: GameState.invasion_kills += 1)
	_foes.append(foe)


func _finish(cleared: bool) -> void:
	GameState.invasion_active = false
	GameState.invasion_done = true
	GameState.invasion_left = 0
	_wave_live = false
	for foe in _foes:
		if is_instance_valid(foe) and not foe.dead:
			foe.queue_free()
			if _lavados:
				_lavados.walkers().erase(foe)
	_foes.clear()
	_queue.clear()
	GameState.say("A maré recuou.")
	GameState.play("bell")
	GameState.add_note("A maré recuou. %d afogados caíram%s. Os outros voltaram para a água." % [GameState.invasion_kills, "" if cleared else " até o amanhecer"])
	GameState.changed.emit()
	GameState.autosave()


## Rounds that left the magazines and the spare ammo since the warning.
func _count_shots() -> void:
	var rounds := GameState.rounds_total()
	if _last_rounds >= 0 and rounds < _last_rounds:
		GameState.invasion_spent += _last_rounds - rounds
	_last_rounds = rounds


func _drop_crate() -> void:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(CRATE_AT + Vector3.UP * 2.5, CRATE_AT + Vector3.DOWN * 2.0, 1)
	var hit := space.intersect_ray(query)
	var base: Vector3 = hit.position if hit else CRATE_AT + Vector3.UP * 0.2
	var x := -0.3
	for entry: Array in CRATE:
		GameState.drop_item(entry[0], entry[1], base + Vector3(x, 0.05, 0.0))
		x += 0.3
	if GameState.inventory.count("pistol") <= 0 and GameState.inventory.count("shotgun") <= 0:
		GameState.drop_item("pistol", 1, base + Vector3(x, 0.05, 0.0))
