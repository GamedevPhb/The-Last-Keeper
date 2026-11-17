extends Node3D
## Easter egg: the crate Portinho leaves on the pier once the giant is solved. `appear()` (called by
## the story scene "portinho_friend") shows it and spawns the pickups once (they are saved with the
## world); a loaded game shows the crate again.

const WOOD := preload("res://materials/m_deadwood.tres")
const AT := Vector3(0.6, 0.0, 46.2)

var _box: Node3D


func _ready() -> void:
	add_to_group("supply_crate")
	position = AT
	_box = Node3D.new()
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.7, 0.5, 0.5)
	body.mesh = mesh
	body.position.y = 0.25
	body.material_override = WOOD
	_box.add_child(body)
	var band := MeshInstance3D.new()
	var band_mesh := BoxMesh.new()
	band_mesh.size = Vector3(0.72, 0.1, 0.52)
	band.mesh = band_mesh
	band.position.y = 0.4
	var blue := StandardMaterial3D.new()
	blue.albedo_color = Color(0.1, 0.35, 0.55)
	blue.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	band.material_override = blue
	_box.add_child(band)
	add_child(_box)
	_box.visible = GameState.portinho_crate_given


func appear() -> void:
	_box.visible = true
	if GameState.portinho_crate_given:
		return
	GameState.portinho_crate_given = true
	var items := ["oil", "battery", "bandage", "water"]
	for i in items.size():
		var spot := global_position + Vector3(-0.35 + 0.23 * i, 0.5, 0.45)
		GameState.drop_item(items[i], 1, spot)
	GameState.play("clunk", global_position)
