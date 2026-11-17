extends Node3D
## The Santa Aurora (HISTORIA 4 #06): a rusted dark cargo ship aground in the SW. Its windows
## glow a pale amber after 00:30, and the Captain stands on deck for a few seconds at 03:05.

const SEA := -1.2
const WINDOWS_AT := 24.0 * 60.0 + 30.0
const CAPTAIN_AT := 27.0 * 60.0 + 5.0
const CAPTAIN_FOR := 4.0 ## game minutes

var _captain: Node3D
var _windows: Node3D
var _forced := false ## story scene "captain": stands on deck whatever the clock says


func _ready() -> void:
	add_to_group("santa_aurora")
	# The greybox hull stays as collision only; the cargo ship replaces what the eye sees.
	for child in get_children():
		if child is MeshInstance3D:
			child.visible = false
	$Hull/Mesh.visible = false
	var ship := Actors.cargo(Color(0.28, 0.18, 0.12), 0.8, 0.3)
	ship.position = Vector3(-40.0, SEA - 1.0, 24.0)
	ship.rotation = Vector3(deg_to_rad(-5.0), deg_to_rad(60.0), deg_to_rad(12.0))
	add_child(ship)
	_add_windows(ship)
	_captain = Actors.character("Character_19_Female_Police", Color(0.7, 0.75, 0.8), 0.4)
	_captain.position = Vector3(0.0, ship.get_meta("deck_y"), ship.get_meta("length") * 0.15)
	_captain.rotation.y = -PI / 2.0
	_captain.visible = false
	ship.add_child(_captain)
	_windows.visible = false


func _process(_delta: float) -> void:
	var minutes: float = GameState.minutes
	_windows.visible = minutes >= WINDOWS_AT and minutes < 30.0 * 60.0
	_captain.visible = _forced or (minutes >= CAPTAIN_AT and minutes < CAPTAIN_AT + CAPTAIN_FOR)


func _add_windows(ship: Node3D) -> void:
	var box: AABB = ship.get_meta("hull_box")
	var mat := ShaderMaterial.new()
	mat.shader = Actors.PSX
	mat.set_shader_parameter("emission", Color(1.0, 0.8, 0.45))
	mat.set_shader_parameter("emission_energy", 1.5)
	mat.set_shader_parameter("albedo", Color(0.9, 0.75, 0.4))
	var quad := BoxMesh.new()
	quad.size = Vector3(1.6, 1.4, 0.2)
	_windows = Node3D.new()
	for i in 6:
		var window := MeshInstance3D.new()
		window.mesh = quad
		window.material_override = mat
		window.position = Vector3(-20.0 + i * 8.0, box.position.y + box.size.y * 0.75, box.end.z)
		_windows.add_child(window)
	ship.get_node("Hull").get_child(0).add_child(_windows)


func force_captain(on: bool) -> void:
	_forced = on
	_captain.visible = on


## Where the Captain stands (the story scene aims the camera here).
func captain_position() -> Vector3:
	return _captain.global_position + Vector3(0.0, 1.2, 0.0)
