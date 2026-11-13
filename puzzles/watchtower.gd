extends "res://puzzles/station.gd"
## Watchtower and binoculars (night 3+): announces the next ship of the radio and its bearing.

const WOOD := preload("res://materials/m_wood.tres")


func _init() -> void:
	unlock_id = "watchtower"
	title = "Olhar pelo binóculo"
	hold_time = 1.0
	per_night = 0


func _use(_by: Node) -> void:
	var desk := get_tree().get_first_node_in_group("radio_desk")
	var info: Dictionary = desk.forecast() if desk and desk.has_method("forecast") else {}
	if info.is_empty():
		GameState.say("Binóculo: o mar está vazio. Sem rádio, ninguém avisa o que vem.")
	elif info.eta <= 0.0:
		GameState.say("Binóculo: %s já está na linha, rumo %s." % [info.call, info.bearing])
	else:
		GameState.say("Binóculo: %s vem pelo %s, em cerca de %d min." % [info.call, info.bearing, ceili(info.eta)])


func _build_body(root: Node3D) -> void:
	_box(root, Vector3(0.25, 4.0, 0.25), Vector3(-0.8, 2.0, -0.8), WOOD)
	_box(root, Vector3(0.25, 4.0, 0.25), Vector3(0.8, 2.0, -0.8), WOOD)
	_box(root, Vector3(0.25, 4.0, 0.25), Vector3(-0.8, 2.0, 0.8), WOOD)
	_box(root, Vector3(0.25, 4.0, 0.25), Vector3(0.8, 2.0, 0.8), WOOD)
	_box(root, Vector3(2.2, 0.2, 2.2), Vector3(0.0, 4.0, 0.0), WOOD, false)
