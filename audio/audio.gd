extends Node
## Audio hub: buses, one-shot effects, looping ambience and the music that tightens with tension.

const POOL_SIZE := 8

var effects := {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_3d: Array[AudioStreamPlayer3D] = []
var _drone: AudioStreamPlayer
var _dissonance: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _whine: AudioStreamPlayer
var _tension := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in ["Music", "SFX", "Ambience"]:
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, "Master")
	effects = Synth.build_effects()
	for i in POOL_SIZE:
		_pool.append(_player("SFX"))
		var spatial := AudioStreamPlayer3D.new()
		spatial.bus = "SFX"
		spatial.max_distance = 40.0
		spatial.unit_size = 5.0
		add_child(spatial)
		_pool_3d.append(spatial)
	_drone = _loop(Synth.drone(4.0, [55.0, 82.5], 0.5, 0.35, 0.8), "Music", -10.0)
	_dissonance = _loop(Synth.drone(4.0, [77.0, 116.0, 233.0], 1.0, 0.6, 0.7), "Music", -60.0)
	_heart = _loop(Synth.heartbeat(0.9), "Music", -60.0)
	_whine = _loop(Synth.drone(4.0, [1760.0, 1772.0], 0.25, 0.9, 0.3), "Music", -60.0)
	_loop(Synth.ambience(6.0, 0.05, 0.33, 0.6, 1.4), "Ambience", -14.0)
	_loop(Synth.ambience(8.0, 0.012, 0.25, 0.7, 5.0), "Ambience", -16.0)
	Settings.apply()


func _process(delta: float) -> void:
	_tension = move_toward(_tension, GameState.tension(), delta * 0.05)
	var t := _tension
	_drone.volume_db = lerpf(-14.0, -7.0, t)
	_dissonance.volume_db = -60.0 if t < 0.15 else lerpf(-34.0, -10.0, clampf((t - 0.15) / 0.85, 0.0, 1.0))
	_heart.volume_db = -60.0 if t < 0.35 else lerpf(-24.0, -8.0, clampf((t - 0.35) / 0.65, 0.0, 1.0))
	_heart.pitch_scale = lerpf(0.85, 1.7, t)
	_whine.volume_db = -60.0 if t < 0.6 else lerpf(-40.0, -22.0, (t - 0.6) / 0.4)


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
