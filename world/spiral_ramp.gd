@tool
class_name SpiralRamp
extends Node3D
## Helical ramp for the lighthouse stairwell, built from tilted box segments.
## CharacterBody3D does not climb steps, so a continuous slope is used instead.
## Starts at angle 0 (+X), height 0, winding counter-clockwise seen from above
## (towards +Z). Generated nodes have no owner, so they are never saved.

@export var height := 16.0
@export var turns := 3.5
@export var inner_radius := 1.3
@export var outer_radius := 2.85
@export var segments_per_turn := 24
@export var thickness := 0.2
@export var material: Material


func _ready() -> void:
	_build()


func _build() -> void:
	for child in get_children():
		child.free()

	var count := int(round(turns * segments_per_turn))
	var step_angle := TAU / segments_per_turn
	var rise := height / count
	var mid_radius := (inner_radius + outer_radius) * 0.5
	# Size by the outer arc so segments overlap at the inner edge instead of gapping.
	var outer_arc := outer_radius * step_angle
	var length := sqrt(outer_arc * outer_arc + rise * rise)
	var pitch := atan2(rise, mid_radius * step_angle)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(outer_radius - inner_radius, thickness, length)
	mesh.material = material
	var shape := BoxShape3D.new()
	shape.size = mesh.size

	var body := StaticBody3D.new()
	body.name = "Collision"
	add_child(body)

	for i in count:
		var angle := (i + 0.5) * step_angle
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		var tangent := Vector3(-sin(angle), 0.0, cos(angle))
		var up := Vector3.UP * cos(pitch) - tangent * sin(pitch)
		var forward := tangent * cos(pitch) + Vector3.UP * sin(pitch)
		var center := radial * mid_radius + Vector3.UP * ((i + 0.5) * rise) - up * (thickness * 0.5)
		var xform := Transform3D(Basis(radial, up, forward), center)

		var visual := MeshInstance3D.new()
		visual.mesh = mesh
		visual.transform = xform
		add_child(visual)

		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.transform = xform
		body.add_child(collider)
