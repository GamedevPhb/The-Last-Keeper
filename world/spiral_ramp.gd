@tool
class_name SpiralRamp
extends Node3D
## Helical ramp for the lighthouse stairwell, built as one continuous mesh.
## CharacterBody3D does not climb steps, so a continuous slope is used instead; the
## collision is a single trimesh of the whole ribbon, with no seams to snag on.
## Starts at angle 0 (+X), height 0, winding counter-clockwise seen from above
## (towards +Z). Generated nodes have no owner, so they are never saved.
## At the top, a "Descer" handle fades to black and drops the keeper at the tower door.

@export var height := 16.0
## Half-integer so the ramp ends at -X, where the lantern room floor opens.
@export var turns := 2.5
@export var inner_radius := 1.3
@export var outer_radius := 2.85
@export var segments_per_turn := 32
@export var thickness := 0.2
@export var material: Material

## Descent shortcut: handle at the top and landing spot at the base (local to the tower).
const DESCEND_HANDLE := Vector3(-2.72, 16.0, -0.35)
const DESCEND_LANDING := Vector3(2.0, 0.05, -1.55)
const FADE_TIME := 0.4
const POST_MATERIAL := preload("res://materials/m_metal.tres")

var _descending := false
var _fade: ColorRect


func _ready() -> void:
	_build()
	if not Engine.is_editor_hint():
		_build_descent()


func _build() -> void:
	for child in get_children():
		child.free()

	var count := int(round(turns * segments_per_turn))
	var step_angle := TAU / segments_per_turn
	var rise := height / count
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var length_along := 0.0
	var mid_radius := (inner_radius + outer_radius) * 0.5
	var step_length := sqrt(pow(mid_radius * step_angle, 2.0) + rise * rise)

	for i in count:
		var a0 := i * step_angle
		var a1 := (i + 1) * step_angle
		var h0 := i * rise
		var h1 := (i + 1) * rise
		var in0 := _point(inner_radius, a0, h0)
		var out0 := _point(outer_radius, a0, h0)
		var in1 := _point(inner_radius, a1, h1)
		var out1 := _point(outer_radius, a1, h1)
		var down := Vector3.DOWN * thickness
		var u0 := length_along
		var u1 := length_along + step_length
		length_along = u1
		var w := outer_radius - inner_radius
		# Top (walked on), underside, then the inner and outer edges.
		_quad(st, [in0, out0, out1, in1], [Vector2(u0, 0), Vector2(u0, w), Vector2(u1, w), Vector2(u1, 0)], Vector3.UP)
		_quad(st, [in0 + down, out0 + down, out1 + down, in1 + down], [Vector2(u0, 0), Vector2(u0, w), Vector2(u1, w), Vector2(u1, 0)], Vector3.DOWN)
		var mid := (a0 + a1) * 0.5
		var radial := Vector3(cos(mid), 0.0, sin(mid))
		_quad(st, [in0, in1, in1 + down, in0 + down], [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, thickness), Vector2(u0, thickness)], -radial)
		_quad(st, [out0, out1, out1 + down, out0 + down], [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, thickness), Vector2(u0, thickness)], radial)
	# Close both ends.
	var start_in := _point(inner_radius, 0.0, 0.0)
	var start_out := _point(outer_radius, 0.0, 0.0)
	_quad(st, [start_in, start_out, start_out + Vector3.DOWN * thickness, start_in + Vector3.DOWN * thickness], [Vector2.ZERO, Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2)], Vector3(0, 0, -1))
	var end_angle := count * step_angle
	var end_in := _point(inner_radius, end_angle, height)
	var end_out := _point(outer_radius, end_angle, height)
	var end_tangent := Vector3(-sin(end_angle), 0.0, cos(end_angle))
	_quad(st, [end_in, end_out, end_out + Vector3.DOWN * thickness, end_in + Vector3.DOWN * thickness], [Vector2.ZERO, Vector2(1, 0), Vector2(1, 0.2), Vector2(0, 0.2)], end_tangent)

	var mesh := st.commit()
	if material:
		mesh.surface_set_material(0, material)
	var visual := MeshInstance3D.new()
	visual.name = "Mesh"
	visual.mesh = mesh
	add_child(visual)

	var body := StaticBody3D.new()
	body.name = "Collision"
	add_child(body)
	var collider := CollisionShape3D.new()
	collider.shape = mesh.create_trimesh_shape()
	body.add_child(collider)


func _point(radius: float, angle: float, y: float) -> Vector3:
	return Vector3(cos(angle) * radius, y, sin(angle) * radius)


## Adds a quad (corners in order around the edge) whose front faces `facing`.
func _quad(st: SurfaceTool, corners: Array, uvs: Array, facing: Vector3) -> void:
	_tri(st, corners[0], corners[1], corners[2], uvs[0], uvs[1], uvs[2], facing)
	_tri(st, corners[0], corners[2], corners[3], uvs[0], uvs[2], uvs[3], facing)


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ua: Vector2, ub: Vector2, uc: Vector2, facing: Vector3) -> void:
	# Godot's front faces wind clockwise: normal = (c - a) x (b - a).
	var normal := (c - a).cross(b - a)
	if normal.dot(facing) < 0.0:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
		normal = -normal
	normal = normal.normalized()
	for v in [[a, ua], [b, ub], [c, uc]]:
		st.set_normal(normal)
		st.set_uv(v[1] * 0.5)
		st.add_vertex(v[0])


## Handle at the top of the ramp that takes the keeper back down without the long walk.
func _build_descent() -> void:
	var root := Node3D.new()
	root.name = "Descend"
	root.position = DESCEND_HANDLE
	add_child(root)

	var post := MeshInstance3D.new()
	var post_mesh := BoxMesh.new()
	post_mesh.size = Vector3(0.08, 1.1, 0.08)
	post_mesh.material = POST_MATERIAL
	post.mesh = post_mesh
	post.position = Vector3(0, 0.55, 0)
	root.add_child(post)
	var grip := MeshInstance3D.new()
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.3, 0.06, 0.06)
	grip_mesh.material = POST_MATERIAL
	grip.mesh = grip_mesh
	grip.position = Vector3(0.12, 1.05, 0)
	root.add_child(grip)

	var handle := Interactable.create("Descer", 0.0, 0.35)
	handle.name = "Interactable"
	handle.position = Vector3(0, 0.95, 0)
	handle.interacted.connect(_on_descend)
	root.add_child(handle)


func _on_descend(by: Node) -> void:
	if _descending or not by.has_method("teleport"):
		return
	_descending = true
	by.set("locked", true)
	var fade := _fade_rect()
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, FADE_TIME)
	await tween.finished
	var landing := Transform3D(Basis(Vector3.UP, -PI * 0.5), DESCEND_LANDING)
	by.teleport(global_transform * landing)
	tween = create_tween()
	tween.tween_property(fade, "color:a", 0.0, FADE_TIME)
	await tween.finished
	by.set("locked", false)
	_descending = false


func _fade_rect() -> ColorRect:
	if _fade:
		return _fade
	var layer := CanvasLayer.new()
	layer.name = "DescendFade"
	layer.layer = 10
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_fade)
	return _fade
