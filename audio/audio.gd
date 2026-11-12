extends Node
## Audio hub: buses, one-shot effects, looping ambience and the adaptive score.
##
## Score: eight one-bar loops (Synth.build_music, D minor, 96 BPM) start together and
## stay locked; only their volumes move. GameState.tension() picks one of four stages
## (calm, uneasy, tense, danger) with hysteresis, at most one step per STAGE_HOLD and
## only on a bar line; layers then crossfade to that stage's mix. A bell sequencer adds
## sparse notes on top, and ships lost / the lamp going out add short cues and a surge.

const POOL_SIZE := 8
## Music layers and their level (dB) when fully in.
const LAYERS := {
	"pad": -6.0, "pulse": -6.0, "ostinato": -6.0, "perc": -5.0,
	"dissonance": -9.0, "heart": -3.0, "cluster": -10.0, "tight": -8.0,
}
## Linear gain of each layer per stage: calm, uneasy, tense, danger.
const STAGE_MIX := {
	"pad": [1.0, 0.8, 0.55, 0.35],
	"pulse": [0.0, 1.0, 0.6, 0.3],
	"ostinato": [0.0, 0.0, 1.0, 1.0],
	"perc": [0.0, 0.0, 1.0, 0.8],
	"dissonance": [0.0, 0.3, 1.0, 0.8],
	"heart": [0.0, 0.0, 0.0, 1.0],
	"cluster": [0.0, 0.0, 0.15, 1.0],
	"tight": [0.0, 0.0, 0.0, 1.0],
}
## Tension needed to climb into stages 1, 2 and 3; dropping back needs HYSTERESIS less.
const STAGE_UP := [0.25, 0.5, 0.78]
const HYSTERESIS := 0.07
## Minimum seconds between two stage changes, so 0 -> 3 always passes through 1 and 2.
const STAGE_HOLD := 5.0
## Crossfade speed, in linear gain per second (about 3 s in, 5 s out).
const FADE_IN := 0.33
const FADE_OUT := 0.2
## Bell: chance of a note per bar and the notes (semitones from D5) for each stage.
const BELL_DB := -9.0
const BELL_CHANCE := [0.55, 0.35, 0.15, 0.0]
const BELL_NOTES := [
	[0, 3, 5, 7, 10, 12, -2],
	[0, 1, 3, 7, 8, -4],
	[-12, -11, -6],
	[],
]
## Sea and wind levels, and how far they duck under a full mix at default music volume.
const AMBIENCE_DB := [-15.0, -17.0]
const DUCK_DB := 6.0
## PS1 SPU bus colour, applied after the samples' own ADPCM grit (see Synth._spu).
## Chain per bus: subtle LOFI crush -> concrete-room reverb -> low-pass (dulls the tail too).
const SPU_CUTOFF_HZ := 9000.0
## LOFI drive: ~0.1 is about 14-15 bits on the mix; above 0.25 it turns chiptune.
const SPU_LOFI_DRIVE := 0.1
const SPU_VERB_ROOM := 0.55
## Low damping keeps the metallic ring of the SPU reverb; the low-pass tames it.
const SPU_VERB_DAMPING := 0.2
const SPU_VERB_PREDELAY_MS := 45.0
## Predelay feedback gives the discrete, slightly echoey "concrete" repeats.
const SPU_VERB_ECHO := 0.35
## The SPU reverb was thin in the bass; this high-passes the wet signal.
const SPU_VERB_HIPASS := 0.25
## Reverb wet level per bus.
const SPU_VERB_WET := {"Music": 0.22, "SFX": 0.15, "Ambience": 0.08}

var effects := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _ambience: Array[AudioStreamPlayer] = []
var _music := {}
var _gains := {}
var _music_streams := {}
var _music_task := -1
var _bells: Array[AudioStreamPlayer] = []
var _next_bell := 0
var _stinger: AudioStreamPlayer
var _rise: AudioStreamPlayer
var _tension := 0.0
var _surge := 0.0
var _stage := 0
var _hold := 0.0
var _rest_bars := 0
var _last_pos := 0.0
## Bell notes waiting in the current bar: x = time in the bar (s), y = semitones.
var _pending: Array[Vector2] = []
var _ships_seen := 0
var _lamp_was_lit := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Ambience"]:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, "Master")
		_spu_chain(index, SPU_VERB_WET[bus])
	effects = Synth.build_effects()
	for i in POOL_SIZE:
		_pool.append(_player("SFX"))
		var spatial := AudioStreamPlayer3D.new()
		spatial.bus = "SFX"
		spatial.max_distance = 40.0
		spatial.unit_size = 5.0
		add_child(spatial)
		_pool_3d.append(spatial)
	_ambience.append(_loop(Synth.ambience(6.0, 0.05, 0.33, 0.6, 1.4), "Ambience", AMBIENCE_DB[0]))
	_ambience.append(_loop(Synth.ambience(8.0, 0.012, 0.25, 0.7, 5.0), "Ambience", AMBIENCE_DB[1]))
	for i in 3:
		_bells.append(_player("Music"))
	_stinger = _player("Music")
	_rise = _player("Music")
	Settings.apply()
	# The score takes a moment to synthesize; do it off the main thread.
	_music_task = WorkerThreadPool.add_task(_build_music, false, "Synth music")


func _spu_chain(index: int, wet: float) -> void:
	var lofi := AudioEffectDistortion.new()
	lofi.mode = AudioEffectDistortion.MODE_LOFI
	lofi.drive = SPU_LOFI_DRIVE
	AudioServer.add_bus_effect(index, lofi)
	var verb := AudioEffectReverb.new()
	verb.room_size = SPU_VERB_ROOM
	verb.damping = SPU_VERB_DAMPING
	verb.spread = 0.4
	verb.predelay_msec = SPU_VERB_PREDELAY_MS
	verb.predelay_feedback = SPU_VERB_ECHO
	verb.hipass = SPU_VERB_HIPASS
	verb.dry = 1.0
	verb.wet = wet
	AudioServer.add_bus_effect(index, verb)
	var low := AudioEffectLowPassFilter.new()
	low.cutoff_hz = SPU_CUTOFF_HZ
	AudioServer.add_bus_effect(index, low)


func _exit_tree() -> void:
	if _music_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_music_task)
		_music_task = -1


func _build_music() -> void:
	_music_streams = Synth.build_music()
	_start_music.call_deferred()


func _start_music() -> void:
	if _music_task < 0:
		return
	WorkerThreadPool.wait_for_task_completion(_music_task)
	_music_task = -1
	for layer: String in LAYERS:
		var player := _player("Music")
		player.stream = _music_streams[layer]
		player.volume_db = -80.0
		_music[layer] = player
		_gains[layer] = 0.0
	# Same frame, same length: the layers start on the same mix step and never drift.
	for layer: String in LAYERS:
		(_music[layer] as AudioStreamPlayer).play()
	_bells[0].stream = _music_streams["bell"]
	_bells[1].stream = _music_streams["bell"]
	_bells[2].stream = _music_streams["bell"]
	_stinger.stream = _music_streams["stinger"]
	_rise.stream = _music_streams["rise"]


func _process(delta: float) -> void:
	_watch_events()
	_surge = move_toward(_surge, 0.0, delta * 0.02)
	_tension = move_toward(_tension, minf(GameState.tension() + _surge, 1.0), delta * 0.25)
	_hold -= delta
	if _music.is_empty():
		return
	var pos := (_music["pad"] as AudioStreamPlayer).get_playback_position()
	if pos < _last_pos:
		_on_bar()
	_last_pos = pos
	for i in range(_pending.size() - 1, -1, -1):
		if pos >= _pending[i].x:
			_ring(_pending[i].y)
			_pending.remove_at(i)
	_mix(delta)


## Short-term tension: a cue plus a surge that fades over ~10 s.
func _watch_events() -> void:
	if GameState.in_game:
		if GameState.ships_lost > _ships_seen:
			_cue(_stinger, -4.0)
			_surge = maxf(_surge, 0.25)
		if _lamp_was_lit and not GameState.lamp_lit:
			_cue(_rise, -7.0)
			_surge = maxf(_surge, 0.15)
	_ships_seen = GameState.ships_lost
	_lamp_was_lit = GameState.lamp_lit


func _cue(player: AudioStreamPlayer, volume_db: float) -> void:
	if player.stream:
		player.volume_db = volume_db
		player.play()


## Stage changes happen on bar lines, one step at a time.
func _on_bar() -> void:
	_pending.clear()
	var target := _target_stage()
	if target != _stage and _hold <= 0.0:
		_stage += signi(target - _stage)
		_hold = STAGE_HOLD
		_rest_bars = 0
	# Silence as a tool: in the calm the pad sometimes thins out for a few bars.
	if _rest_bars > 0:
		_rest_bars -= 1
	elif _stage == 0 and randf() < 0.1:
		_rest_bars = randi_range(2, 3)
	var notes: Array = BELL_NOTES[_stage]
	if notes.is_empty() or randf() >= BELL_CHANCE[_stage]:
		return
	var beat := randi_range(0, Synth.BEATS - 1)
	_pending.append(Vector2(beat * Synth.BEAT, notes.pick_random()))
	if randf() < 0.4 and beat < Synth.BEATS - 1:
		_pending.append(Vector2((beat + randf_range(0.5, 1.0)) * Synth.BEAT, notes.pick_random()))


func _target_stage() -> int:
	var stage := _stage
	while stage < 3 and _tension >= STAGE_UP[stage]:
		stage += 1
	while stage > 0 and _tension < STAGE_UP[stage - 1] - HYSTERESIS:
		stage -= 1
	return stage


func _mix(delta: float) -> void:
	var energy := 0.0
	var swell := lerpf(-3.0, 0.0, _tension)
	for layer: String in LAYERS:
		var target: float = STAGE_MIX[layer][_stage]
		if layer == "pad" and _rest_bars > 0:
			target *= 0.3
		var gain: float = _gains[layer]
		gain = move_toward(gain, target, delta * (FADE_IN if target > gain else FADE_OUT))
		_gains[layer] = gain
		energy += gain
		(_music[layer] as AudioStreamPlayer).volume_db = LAYERS[layer] + swell + linear_to_db(maxf(gain, 0.0001))
	# Duck the sea under the score, scaled by the music option (no music, no ducking).
	var music_level: float = Settings.values["music"]
	var duck := DUCK_DB * clampf(energy / 3.0, 0.0, 1.0) * clampf(music_level / 0.7, 0.0, 1.0)
	for i in _ambience.size():
		_ambience[i].volume_db = AMBIENCE_DB[i] - duck


func _ring(semitones: float) -> void:
	var player := _bells[_next_bell]
	_next_bell = (_next_bell + 1) % _bells.size()
	if not player.stream:
		return
	player.pitch_scale = pow(2.0, semitones / 12.0)
	player.volume_db = BELL_DB + randf_range(-3.0, 0.0) - maxf(semitones, 0.0) * 0.2
	player.play()


func play(sound_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	_play_on(_pool, sound_name, volume_db, pitch)


func play_at(sound_name: String, position: Vector3, volume_db := 0.0) -> void:
	for spatial in _pool_3d:
		if not spatial.playing and effects.has(sound_name):
			spatial.stream = effects[sound_name]
			spatial.global_position = position
			spatial.volume_db = volume_db
			spatial.play()
			return


func _play_on(pool: Array[AudioStreamPlayer], sound_name: String, volume_db: float, pitch: float) -> void:
	if not effects.has(sound_name):
		return
	for player in pool:
		if not player.playing:
			player.stream = effects[sound_name]
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return


func _player(bus: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	add_child(player)
	return player


func _loop(stream: AudioStream, bus: String, volume_db: float) -> AudioStreamPlayer:
	var player := _player(bus)
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	return player
