class_name Pickup
extends Node3D
## An item stack lying in the world: a small tinted crate with an Interactable ("Pegar").
## Used for dropped items and for the fixed supplies (house, shed, pantry). Whatever does not
## fit in the inventory stays on the ground.

const INVENTORY := preload("res://items/inventory.gd")
const COLORS := {
	"flashlight": Color(0.55, 0.5, 0.3),
	"battery": Color(0.2, 0.55, 0.3),
	"lens_cleaner": Color(0.6, 0.8, 0.85),
	"radio": Color(0.25, 0.3, 0.25),
	"oil": Color(0.75, 0.55, 0.15),
	"fuel": Color(0.6, 0.15, 0.1),
	"water": Color(0.45, 0.65, 0.75),
	"can": Color(0.6, 0.62, 0.6),
	"biscuit": Color(0.78, 0.65, 0.4),
	"bandage": Color(0.9, 0.88, 0.8),
	"wood": Color(0.45, 0.3, 0.15),
	"algae": Color(0.2, 0.45, 0.25),
	"fat": Color(0.85, 0.8, 0.6),
	"coal": Color(0.1, 0.1, 0.12),
	"scrap": Color(0.5, 0.35, 0.25),
	"fish": Color(0.55, 0.65, 0.7),
}

@export var item := "oil"
@export var count := 1

var _switch: Interactable


func _ready() -> void:
	add_to_group("pickups")
	var model := Actors.item_model(item, true)
	if model:
		var size: Vector3 = model.get_meta("size")
		model.position.y = size.y / 2.0
		add_child(model)
	else:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.18, 0.2, 0.14) if item in ["oil", "fuel", "water"] else Vector3(0.2, 0.08, 0.14)
		mesh.mesh = box
		mesh.position.y = box.size.y / 2.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = COLORS.get(item, Color(0.5, 0.5, 0.5))
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mesh.material_override = mat
		add_child(mesh)
	_switch = Interactable.create("", 0.0, 0.3)
	_switch.name = "Take"
	_switch.position.y = 0.12
	add_child(_switch)
	_switch.interacted.connect(collect)
	_refresh()


func collect(_by: Node = null) -> void:
	var left: int = GameState.inventory.add(item, count)
	if left == count:
		GameState.say("Inventário cheio.")
		return
	GameState.play("pickup", global_position)
	var taken := count - left
	count = left
	# Always confirm what went into the pack and how many are carried now (tester feedback).
	var text := "%s%s (%d na mochila)" % [INVENTORY.item_name(item), "" if taken == 1 else " x%d" % taken, GameState.inventory.count(item)]
	if count <= 0:
		GameState.say(text)
		queue_free()
	else:
		GameState.say("%s. Inventário cheio: ficou %d no chão." % [text, count])
		_refresh()


func _refresh() -> void:
	var label := INVENTORY.item_name(item)
	_switch.prompt = "Pegar %s" % label if count == 1 else "Pegar %s (x%d)" % [label, count]
