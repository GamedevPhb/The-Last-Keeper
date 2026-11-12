extends Node3D
## Fixed food and water sources (GDD 4.10): the house cistern (drink in place, endless),
## the house cupboard and the shed shelf. The pantry under the cellar hatch is paid out by
## `cellar_lock.gd`. Props are greybox boxes built in code; items lie on them as pickups.

const PICKUP := preload("res://items/pickup.gd")
const CISTERN := Vector3(24.85, 0.0, 6.6)
const DRINK := 35.0
const SHELVES := [
	{"name": "Cupboard", "at": Vector3(27.2, 0.0, 5.25), "size": Vector3(0.8, 1.0, 0.35), "items": [["can", 1], ["bandage", 1]]},
	{"name": "ShedShelf", "at": Vector3(-19.0, 0.0, 13.2), "size": Vector3(0.9, 0.8, 0.35), "items": [["water", 1], ["biscuit", 2]]},
]

var _cistern: Interactable


func _ready() -> void:
	var metal: Material = load("res://materials/m_metal.tres")
	var wood: Material = load("res://materials/m_wood.tres") if ResourceLoader.exists("res://materials/m_wood.tres") else metal
	var tank := _solid("Cistern", CISTERN, _cylinder(0.32, 0.9), CylinderShape3D.new(), metal)
	(tank.get_child(1).shape as CylinderShape3D).radius = 0.32
	(tank.get_child(1).shape as CylinderShape3D).height = 0.9
	_cistern = Interactable.create("Beber da cisterna", 2.0, 0.4)
	_cistern.name = "Drink"
	_cistern.position = Vector3(0.0, 0.95, 0.0)
	tank.add_child(_cistern)
	_cistern.interacted.connect(drink)
	for shelf: Dictionary in SHELVES:
		var box := BoxMesh.new()
		box.size = shelf.size
		var shape := BoxShape3D.new()
		shape.size = shelf.size
		var body := _solid(shelf.name, shelf.at, box, shape, wood)
		var x: float = -shelf.size.x / 2.0 + 0.2
		for entry: Array in shelf.items:
			var pickup: Node3D = PICKUP.new()
			pickup.item = entry[0]
			pickup.count = entry[1]
			pickup.position = Vector3(x, shelf.size.y, 0.0)
			body.add_child(pickup)
			x += 0.3


## The cistern: thirst +35, as often as the keeper likes.
func drink(_by: Node = null) -> void:
	GameState.thirst = minf(GameState.thirst + DRINK, 100.0)
	GameState.play("drink", CISTERN)
	GameState.say("Água fria da cisterna. A sede passa.")


func _solid(node_name: String, at: Vector3, mesh: Mesh, shape: Shape3D, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	add_child(body)
	body.global_position = at
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	var height: float = mesh.size.y if mesh is BoxMesh else (mesh as CylinderMesh).height
	visual.position.y = height / 2.0
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = height / 2.0
	body.add_child(collision)
	return body


func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh
