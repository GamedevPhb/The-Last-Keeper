extends Node3D
## Monta os MultiMesh de pinheiros (tronco + copa) a partir de `spots` (x, z, escala, giro); a altura vem do terreno.

@export var spots := PackedFloat32Array()
@export var trunk_material: Material
@export var crown_material: Material

const Terrain := preload("res://world/terrain.gd")


func _ready() -> void:
	var n := spots.size() / 4
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.14
	trunk.bottom_radius = 0.22
	trunk.height = 3.0
	trunk.radial_segments = 5
	trunk.rings = 1
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 1.7
	crown.height = 5.0
	crown.radial_segments = 6
	crown.rings = 1
	_build("Trunks", trunk, 1.5, trunk_material, n)
	_build("Crowns", crown, 5.0, crown_material, n)


func _build(nm: String, mesh: Mesh, lift: float, mat: Material, n: int) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	for i in n:
		var s := spots[i * 4 + 2]
		var b := Basis().rotated(Vector3.UP, spots[i * 4 + 3]).scaled(Vector3(s, s, s))
		mm.set_instance_transform(i, Transform3D(b, Vector3(spots[i * 4], Terrain.height_at(spots[i * 4], spots[i * 4 + 1]) + lift * s, spots[i * 4 + 1])))
	var mi := MultiMeshInstance3D.new()
	mi.name = nm
	mi.multimesh = mm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
