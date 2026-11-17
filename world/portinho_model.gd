extends RefCounted
## The low-poly Portinho (mascot of Porto Indie): loads res://assets/portinho/portinho.glb
## (root Portinho; Body, Hat, ArmL, ArmR, LegL, LegR; feet at y=0, 1.8 m, facing -Z). While the
## file is missing it builds a placeholder of stacked boxes with the same node names.

const PATH := "res://assets/portinho/portinho.glb"
const BEIGE := Color(0.95, 0.84, 0.62)
const BLUE := Color(0.0, 0.2, 0.42)
const CYAN := Color(0.24, 0.72, 0.84)
const BLACK := Color(0.05, 0.05, 0.05)


static func create() -> Node3D:
	if ResourceLoader.exists(PATH):
		var scene := load(PATH) as PackedScene
		if scene:
			return scene.instantiate() as Node3D
	return _placeholder()


const PSX := preload("res://shaders/psx_lit.gdshader")


## Per surface (the face and windows are alpha quads, so no material_override): a nearest-filtered
## copy of the glb material. `psx` swaps opaque surfaces for psx_lit (tinted by `tint`); the others stay
## StandardMaterial3D (unshaded / fog-free when asked). Returns [material, base_color] pairs of the
## StandardMaterial3D ones so callers can re-tint them.
static func prepare(root: Node, unshaded: bool, fog_free: bool, psx := false, tint := Color.WHITE) -> Array:
	var out := []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.mesh == null:
			continue
		for i in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(i) as BaseMaterial3D
			if source == null:
				source = StandardMaterial3D.new()
			if psx and source.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
				var shader_mat := ShaderMaterial.new()
				shader_mat.shader = PSX
				if source.albedo_texture:
					shader_mat.set_shader_parameter("albedo_texture", source.albedo_texture)
				var c := source.albedo_color * tint
				shader_mat.set_shader_parameter("albedo", Color(c.r, c.g, c.b, 1.0))
				mesh.set_surface_override_material(i, shader_mat)
				continue
			var mat := source.duplicate() as StandardMaterial3D
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			if unshaded:
				mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.disable_fog = fog_free
			mat.albedo_color = source.albedo_color * tint
			mesh.set_surface_override_material(i, mat)
			out.append([mat, source.albedo_color])
	return out


static func _placeholder() -> Node3D:
	var root := Node3D.new()
	root.name = "Portinho"
	_box(root, "Body", Vector3(0.7, 1.0, 0.6), Vector3(0, 0.9, 0), BEIGE)
	_box(root, "Hat", Vector3(0.8, 0.3, 0.7), Vector3(0, 1.55, 0), BLUE)
	var arm_l := _box(root, "ArmL", Vector3(0.18, 0.6, 0.18), Vector3(-0.45, 1.25, 0), BEIGE, Vector3(0, -0.3, 0))
	arm_l.rotation.z = deg_to_rad(-150.0) # thumbs-up arm raised
	_box(root, "ArmR", Vector3(0.18, 0.6, 0.18), Vector3(0.45, 1.25, 0), BLACK, Vector3(0, -0.3, 0))
	_box(root, "LegL", Vector3(0.18, 0.4, 0.18), Vector3(-0.2, 0.4, 0), BLACK, Vector3(0, -0.2, 0))
	_box(root, "LegR", Vector3(0.18, 0.4, 0.18), Vector3(0.2, 0.4, 0), BLACK, Vector3(0, -0.2, 0))
	return root


static func _box(parent: Node3D, node_name: String, size: Vector3, at: Vector3, color: Color, mesh_offset := Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	var box := BoxMesh.new()
	box.size = size
	node.mesh = box
	node.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	if mesh_offset != Vector3.ZERO:
		# Pivot at the joint: shift the mesh itself via a transform-free trick (center offset).
		var offset := Node3D.new()
		node.mesh = null
		var inner := MeshInstance3D.new()
		inner.mesh = box
		inner.material_override = mat
		inner.position = mesh_offset
		node.add_child(inner)
		node.material_override = null
	parent.add_child(node)
	return node
