extends Node
## Wires gameplay events to sounds and runs the in-world loops (generator hum, lamp clockwork).

const GENERATOR_AT := Vector3(-20.4, 1.0, 14.7)
const LAMP_AT := Vector3(0.0, 17.0, -12.0)

var _hum: AudioStreamPlayer3D
var _ticking: AudioStreamPlayer3D


func _ready() -> void:
	GameState.start_night()
	GameState.sound.connect(_on_sound)
	GameState.changed.connect(_sync_loops)
	_hum = _spatial_loop(Synth.hum(0.8), GENERATOR_AT, 12.0)
	_ticking = _spatial_loop(Synth.ticking(0.6), LAMP_AT, 14.0)
	# The player is a sibling that may not be ready yet.
	var player := get_parent().get_node_or_null("Player") as Player
	if player:
		player.stepped.connect(func() -> void: Audio.play("step", -8.0, randf_range(0.85, 1.15)))
		player.jumped.connect(func() -> void: Audio.play("jump", -6.0))
		player.landed.connect(func() -> void: Audio.play("land", -6.0))
		player.interacted.connect(func(_target: Interactable) -> void: Audio.play("click", -4.0))
	Settings.apply()


func _spatial_loop(stream: AudioStream, at: Vector3, distance: float) -> AudioStreamPlayer3D:
	var spatial := AudioStreamPlayer3D.new()
	spatial.stream = stream
	spatial.bus = "SFX"
	spatial.unit_size = 4.0
	spatial.max_distance = distance * 3.0
	add_child(spatial)
	spatial.global_position = at
	return spatial


func _sync_loops() -> void:
	_set_playing(_hum, GameState.generator_on)
	_set_playing(_ticking, GameState.lamp_lit)


func _set_playing(player: AudioStreamPlayer3D, on: bool) -> void:
	if on and not player.playing:
		player.play()
	elif not on and player.playing:
		player.stop()


func _on_sound(sound_name: String, position: Vector3) -> void:
	if position == Vector3.INF:
		Audio.play(sound_name)
	else:
		Audio.play_at(sound_name, position)
