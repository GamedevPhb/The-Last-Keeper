extends Node3D
## Supply chest at the pier: the first things the keeper needs to start the night.

@export var oil_cans := 1
@export var fuel_cans := 1

var _open := false
var _interactable: Interactable


func _ready() -> void:
	add_to_group("saveable")
	_interactable = Interactable.create("Abrir o baú", 1.0, 0.7)
	_interactable.name = "Open"
	_interactable.position = Vector3(-0.7, 0.6, 47.2)
	add_child(_interactable)
	_interactable.interacted.connect(_on_open)


func save_state() -> Dictionary:
	return {"open": _open}


func load_state(data: Dictionary) -> void:
	if data.get("open", false) and not _open:
		_open = true
		_interactable.enabled = false
		_lift_lid()


func _lift_lid() -> void:
	var lid := get_node_or_null("Lid")
	if lid:
		lid.rotation_degrees.x = -75.0
		lid.position += Vector3(0, 0.18, -0.28)


func _on_open(_by: Node) -> void:
	if _open:
		return
	_open = true
	_interactable.enabled = false
	GameState.chest_opened = true
	GameState.play("creak", _interactable.global_position)
	var at := _interactable.global_position
	GameState.give("flashlight", 1, at)
	GameState.give("radio", 1, at)
	GameState.give("oil", oil_cans, at)
	GameState.give("fuel", fuel_cans, at)
	_lift_lid()
	GameState.say("No baú: lanterna, rádio portátil, uma lata de óleo e uma de combustível. [Tab] inventário, [F] lanterna, [R] rádio.")
