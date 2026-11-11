extends Node3D
## Supply chest at the pier: the first things the keeper needs to start the night.

@export var oil_cans := 1
@export var fuel_cans := 1

var _open := false
var _interactable: Interactable


func _ready() -> void:
	_interactable = Interactable.create("Abrir o baú", 1.0, 0.7)
	_interactable.name = "Open"
	_interactable.position = Vector3(-0.7, 0.6, 47.2)
	add_child(_interactable)
	_interactable.interacted.connect(_on_open)


func _on_open(_by: Node) -> void:
	if _open:
		return
	_open = true
	_interactable.enabled = false
	GameState.chest_opened = true
	GameState.has_flashlight = true
	GameState.oil_cans += oil_cans
	GameState.fuel_cans += fuel_cans
	var lid := get_node_or_null("Lid")
	if lid:
		lid.rotation_degrees.x = -75.0
		lid.position += Vector3(0, 0.18, -0.28)
	GameState.say("No baú: uma lanterna, uma lata de óleo e uma lata de combustível. [F] liga a lanterna.")
