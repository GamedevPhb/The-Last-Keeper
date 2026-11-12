class_name Actors
extends RefCounted
## Builders for the imported models: the cargo ship (one mesh, tinted per ship) and the rigged
## characters (Mixamo FBX). Every surface keeps its original texture but renders with
## psx_lit.gdshader, so the PS1 look (snap, affine, nearest) carries over.

const PSX := preload("res://shaders/psx_lit.gdshader")
const CARGO := "res://assets/navios/general_cargo.glb"
const CHARS := "res://assets/personagens_psx/Models/%s.fbx"
const POSE := preload("res://world/actor_pose.gd")
const HUMAN_HEIGHT := 1.8


## Swaps every surface under `node` for a psx_lit copy of its albedo, mixed `amount` toward `tint`.
static func psx_skin(node: Node, tint := Color.WHITE, amount := 0.0) -> void:
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mi := found as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := (mi.get_surface_override_material(i) if mi.get_surface_override_material(i) else mi.mesh.surface_get_material(i)) as BaseMaterial3D
			var mat := ShaderMaterial.new()
			mat.shader = PSX
			var color := Color.WHITE
			if src:
				color = src.albedo_color
				if src.albedo_texture:
					mat.set_shader_parameter("albedo_texture", src.albedo_texture)
			var mixed := Color.WHITE.lerp(tint, amount)
			mat.set_shader_parameter("albedo", Color(color.r * mixed.r, color.g * mixed.g, color.b * mixed.b, 1.0))
			mi.set_surface_override_material(i, mat)


## A rigged character at human scale, feet on y = 0, given a procedural pose (`actor_pose.gd`: the FBX clip is one T-pose frame).
static func character(file: String, tint := Color.WHITE, amount := 0.0, height := HUMAN_HEIGHT) -> Node3D:
	var root := Node3D.new()
	root.name = file
	var model := (load(CHARS % file) as PackedScene).instantiate() as Node3D
	psx_skin(model, tint, amount)
	root.add_child(model)
	var bounds := _bounds(model)
	var s := height / maxf(bounds.size.y, 0.01)
	model.scale = Vector3.ONE * s
	model.position.y = -bounds.position.y * s
	POSE.attach(root)
	return root


## Imported item models (weapons, shells): file under assets/armas/, longest side in meters (0 =
## keep the native size) and, for items lying on the ground, an extra rotation in degrees.
const ITEM_MODELS := {
	"axe": {"file": "machado.glb", "length": 0.7, "lying": Vector3(0.0, 0.0, 90.0)},
	"pistol": {"file": "pistola/pistola.fbx", "length": 0.2, "lying": Vector3.ZERO},
	"shotgun": {"file": "espingarda.glb", "length": 0.0, "lying": Vector3.ZERO},
	"shells": {"file": "cartucho_12.glb", "length": 0.07, "lying": Vector3.ZERO},
	"ammo_pistol": {"file": "cartucho_12.glb", "length": 0.04, "lying": Vector3.ZERO},
}
const P38_TEXTURES := {"cima": "res://assets/armas/pistola/textures/p_38_top.png", "base": "res://assets/armas/pistola/textures/p_38_Base.png"}


## An item model in the PS1 material, scaled to its length and centred on its own bounding box
## (so it spins around the middle). Null if `id` has no model. The node keeps the size in meta
## "size" (Vector3). `lying` applies the resting rotation for pickups on the ground.
static func item_model(id: String, lying := false) -> Node3D:
	if not ITEM_MODELS.has(id):
		return null
	var info: Dictionary = ITEM_MODELS[id]
	var model := (load("res://assets/armas/" + info.file) as PackedScene).instantiate() as Node3D
	if id == "pistol":
		_texture_p38(model)
	psx_skin(model)
	var root := Node3D.new()
	root.name = id.capitalize()
	var inner := Node3D.new()
	inner.add_child(model)
	root.add_child(inner)
	var bounds := _bounds(model)
	var length: float = info.length
	var s: float = 1.0 if length <= 0.0 else length / maxf(bounds.get_longest_axis_size(), 0.001)
	model.scale = Vector3.ONE * s
	model.position = -(bounds.position + bounds.size / 2.0) * s
	if lying:
		inner.rotation_degrees = info.lying
	var size: Vector3 = bounds.size * s
	if lying:
		var rot := Basis.from_euler(inner.rotation)
		size = Vector3(absf(rot.x.x) * size.x + absf(rot.y.x) * size.y + absf(rot.z.x) * size.z,
			absf(rot.x.y) * size.x + absf(rot.y.y) * size.y + absf(rot.z.y) * size.z,
			absf(rot.x.z) * size.x + absf(rot.y.z) * size.y + absf(rot.z.z) * size.z)
	root.set_meta("size", size)
	return root


## The P38 FBX lost its textures: top half and base get their PNGs back.
static func _texture_p38(model: Node) -> void:
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mi := found as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			var mat: BaseMaterial3D = src.duplicate() if src else StandardMaterial3D.new()
			var top := src != null and "cima" in src.resource_name
			mat.albedo_texture = load(P38_TEXTURES.cima if top else P38_TEXTURES.base)
			mi.set_surface_override_material(i, mat)


## The pose driver of a character made here (set `mode`, `talking`); null if it has none.
static func pose_of(character: Node) -> Node:
	return character.get_node_or_null("ActorPose") if character else null


## Tomé, the protagonist (assets/personagem/keeper.glb), feet on y = 0, in the PS1 material.
static func keeper() -> Node3D:
	var root := Node3D.new()
	root.name = "Keeper"
	var model := (load("res://assets/personagem/keeper.glb") as PackedScene).instantiate() as Node3D
	psx_skin(model)
	root.add_child(model)
	# keeper.glb has a skeleton and idle/walk clips, but it gets the same procedural pose as the
	# Mixamo cast so every character in the shots moves alike (and talks with `talking`).
	POSE.attach(root)
	return root


## The cargo ship with its bow to -Z and the waterline at y = 0. The hull node is scaled by `s`;
## meta "deck_y" and "length" are already in the scaled size (for captains and moorings).
static func cargo(tint: Color, amount: float, s: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Cargo"
	var model := (load(CARGO) as PackedScene).instantiate() as Node3D
	psx_skin(model, tint, amount)
	var hull := model.get_node("Cube") as MeshInstance3D
	var box := hull.get_aabb()
	model.position.y = -(box.position.y + box.size.y * 0.3)
	model.rotation.y = -PI / 2.0
	var scaled := Node3D.new()
	scaled.name = "Hull"
	scaled.scale = Vector3.ONE * s
	scaled.add_child(model)
	root.add_child(scaled)
	root.set_meta("deck_y", (model.position.y + box.end.y) * s)
	root.set_meta("length", box.size.x * s)
	root.set_meta("hull_box", box)
	return root


static func _bounds(model: Node3D) -> AABB:
	var out := AABB()
	var first := true
	for found in model.find_children("*", "MeshInstance3D", true, false):
		var mi := found as MeshInstance3D
		var box := mi.get_aabb()
		var node: Node = mi
		var xf := Transform3D.IDENTITY
		while node != model and node is Node3D:
			xf = (node as Node3D).transform * xf
			node = node.get_parent()
		box = xf * box
		out = box if first else out.merge(box)
		first = false
	return out
