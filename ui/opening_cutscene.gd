class_name OpeningCutscene
extends "res://ui/story_scene.gd"
## The opening (docs/CUTSCENE_ABERTURA.md), ~52 s: arrival at the pier, the essentials of the
## talk (the sealed lighthouse, the ninth keeper who vanished, "Volto às seis") and the boat
## leaving for the ship at the horizon. Everything else the old version explained comes later as
## story scenes (`story_scene.gd`, `GameState.SCENE_TRIGGERS`). Emits `finished` on the first
## playable frame, with the keeper on the pier next to the chest.

const PIER_SPAWN := Vector3(0.4, 0.05, 49.8)
const KEEPER_AT := Vector3(0.4, 0.0, 47.0)
## The shot that follows the boat out to the ship at the horizon.
const SAIL_FROM := Vector3(3.3, SEA, 47.5)
const SAIL_TO := Vector3(-30.0, SEA, 101.5)
const PIER_TWO := {"from": Vector3(7.0, 1.4, 44.5), "to": Vector3(6.0, 1.6, 45.5),
	"look_from": Vector3(1.8, 1.0, 47.2), "look_to": Vector3(1.8, 1.0, 47.2)}

## Lines are [pause before, text]: the boatman plain, the keeper with a dash.
const OPENING := {"shots": [
	{"t": 0.0, "len": 3.0, "black": true, "title": "PONTO 7\nLacrado há trinta anos."},
	{"t": 3.0, "len": 9.0, "from": Vector3(14, 1.3, 90), "to": Vector3(8.5, 1.4, 60),
		"look_from": Vector3(2, 1.2, 48), "look_to": Vector3(2, 1.2, 48),
		"lines": [[0.8, "Ponto 7. Ninguém pede o Sete."], [0.4, "O senhor pediu."], [0.6, "— Pedi."]], "cue": "gust"},
	{"t": 12.0, "len": 8.0, "from": Vector3(9, 1.0, 34), "to": Vector3(9, 1.0, 34),
		"look_from": Vector3(0, 1, -12), "look_to": Vector3(0, 17.5, -12),
		"lines": [[0.6, "O farol é seu. Lacrado há trinta anos."], [0.4, "Agora reabriram. Ninguém me disse por quê."]],
		"cue": "metal_creak"},
	{"t": 20.0, "len": 17.0, "from": PIER_TWO.from, "to": PIER_TWO.to,
		"look_from": PIER_TWO.look_from, "look_to": PIER_TWO.look_to,
		"lines": [[0.6, "Dez vigias, contando o senhor."], [0.4, "Oito estão enterrados atrás do farol."],
			[0.6, "— E o nono?"], [0.5, "Sumiu na noite do Santa Aurora."],
			[0.5, "Volto às seis. Se a luz estiver acesa."]], "cue": "pier_creak"},
	{"t": 37.0, "len": 12.0, "from": Vector3(0.0, 1.7, 50.5), "to": Vector3(0.0, 1.7, 50.5),
		"look_from": Vector3(-1, 1, 70), "look_to": Vector3(-1, 1, 70), "sail": true, "track": true, "cue": "boat_bell"},
	{"t": 49.0, "len": 3.0, "black": true, "title": "THE LAST KEEPER"},
]}

var _keeper: Node3D
var _boatman: Node3D


func _scene_data() -> Dictionary:
	return OPENING


func _begin() -> void:
	if _player:
		_player.global_position = PIER_SPAWN
		_player.rotation = Vector3.ZERO
		_player.velocity = Vector3.ZERO
	_keeper = Actors.keeper()
	get_parent().add_child(_keeper)
	_keeper.global_position = KEEPER_AT
	_keeper.rotation.y = PI / 2.0
	_boatman = get_tree().get_first_node_in_group("boatman") as Node3D


## The boatman talks with the plain lines, the keeper with the dashed ones.
func _speaking(text: String, on: bool) -> void:
	var keeper_line := text.begins_with("—")
	var pose: Node = Actors.pose_of(_keeper) if keeper_line else null
	if keeper_line and pose:
		pose.talking = on
	elif not keeper_line and _boatman:
		_boatman.set_talking(on)


func _shot_extra(shot: Dictionary, k: float) -> void:
	if shot.get("sail", false) and _boatman:
		_boatman.sail_to(SAIL_FROM.lerp(SAIL_TO, smoothstep(0.0, 1.0, k)))
		if k >= 0.97:
			_boatman.board() # behind the hull


func _look(shot: Dictionary, target: Vector3) -> void:
	if shot.get("track", false) and _boatman:
		_camera.look_at(_boatman.global_position + Vector3(0.0, 0.8, 0.0))
	else:
		_camera.look_at(target)


func _end() -> void:
	if _boatman:
		_boatman.set_talking(false)
		_boatman.board()
	if _keeper:
		_keeper.queue_free()
	if _player:
		_player.global_position = PIER_SPAWN
		_player.rotation = Vector3.ZERO
		_player.velocity = Vector3.ZERO
