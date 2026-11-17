extends Node3D
## Easter egg: the tin Portinho doll on the radio desk (after the giant is solved). "Portinho"
## says a hint for the nearest station; "Levar" puts it in the inventory (item "portinho"; use = hint).

const MODEL := preload("res://world/portinho_model.gd")
const SCALE := 0.15 ## 1.8 m model -> a 27 cm tin doll
const RUST := Color(0.78, 0.72, 0.66)

var _hint: Interactable
var _take: Interactable
var _model: Node3D


func _ready() -> void:
	var station := get_tree().get_first_node_in_group("radio_desk") as Node3D
	position = (station.global_position if station else Vector3(25.25, 0.9, 5.4)) + Vector3(-0.3, -0.1, -0.15)
	_model = MODEL.create()
	_model.scale = Vector3.ONE * SCALE
	_model.rotation.y = PI # faces the keeper at the desk (+Z)
	add_child(_model)
	# Faded rust on opaque parts (psx_lit); the alpha face quads stay standard, a little metallic.
	for pair: Array in MODEL.prepare(_model, false, false, true, RUST):
		var mat: StandardMaterial3D = pair[0]
		mat.metallic = 0.4
		mat.roughness = 0.8
	_hint = Interactable.create("Portinho", 0.0, 0.11)
	_hint.name = "Hint"
	_hint.position.y = 0.1
	add_child(_hint)
	_hint.interacted.connect(func(_by: Node) -> void: GameState.portinho_hint())
	_take = Interactable.create("Levar o Portinho", 0.0, 0.08)
	_take.name = "Take"
	_take.position.y = 0.3
	add_child(_take)
	_take.interacted.connect(_on_take)
	_sync()


func _process(_delta: float) -> void:
	_sync()


func _sync() -> void:
	var present := GameState.portinho_doll_present()
	visible = present
	_hint.enabled = present
	_take.enabled = present


func _on_take(_by: Node) -> void:
	if GameState.inventory.add("portinho", 1) > 0:
		GameState.say("Inventário cheio.")
		return
	GameState.portinho_doll_taken = true
	GameState.play("pickup", global_position)
	GameState.say("Você guarda o Portinho no bolso. O polegar continua para cima.")
	_sync()
