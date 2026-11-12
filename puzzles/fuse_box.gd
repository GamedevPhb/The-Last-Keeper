extends Marker3D
## Breaker panel on the house wall: one Interactable opens the brass console
## (`ui/fuse_console.gd`); the generator only feeds POWER_CAPACITY circuits at once.
## The box is signposted in the world: an engraved sign, a pilot light per circuit and a
## status lamp that glows green (powered), amber (generator stopped) or dim red (all off).

## Preloaded instead of the class_name, so this compiles before the global class cache is rebuilt.
const FUSE_CONSOLE := preload("res://ui/fuse_console.gd")
const CIRCUITS := ["radio", "house", "motor"]
const GREEN := Color(0.3, 1.0, 0.35)
const AMBER := Color(1.0, 0.6, 0.1)
const DARK := Color(0.2, 0.05, 0.04)

var _switch: Interactable
var _console: Node
var _pilots: Array[StandardMaterial3D] = []
var _status: OmniLight3D


func _ready() -> void:
	_switch = Interactable.create("Quadro de força", 0.0, 0.42)
	_switch.name = "Panel"
	_switch.position = Vector3(0.0, 0.0, 0.1)
	add_child(_switch)
	_switch.interacted.connect(_on_interacted)
	_build_sign()
	GameState.changed.connect(_refresh)
	_refresh()


func _on_interacted(by: Node) -> void:
	if _console == null:
		_console = FUSE_CONSOLE.new()
		_console.box = self
		add_child(_console)
	_console.open(by as Player)


func _refresh() -> void:
	var used: int = GameState.breakers.values().count(true)
	_switch.prompt = "Quadro de força (%d/%d ligados)" % [used, GameState.POWER_CAPACITY]
	var any_powered := false
	for i in CIRCUITS.size():
		var on: bool = GameState.breakers[CIRCUITS[i]]
		var color := DARK
		if on:
			color = GREEN if GameState.generator_on else AMBER
			any_powered = any_powered or GameState.generator_on
		_pilots[i].albedo_color = color
	if any_powered:
		_status.light_color = GREEN
		_status.light_energy = 0.8
	elif used > 0:
		_status.light_color = AMBER
		_status.light_energy = 0.6
	else:
		_status.light_color = Color(1.0, 0.2, 0.1)
		_status.light_energy = 0.25


func _build_sign() -> void:
	var plaque := Label3D.new()
	plaque.text = "QUADRO DE FORÇA"
	plaque.font = load("res://ui/fonts/DejaVuSerifCondensed-Bold.ttf")
	plaque.font_size = 24
	plaque.pixel_size = 0.0036
	plaque.outline_size = 6
	plaque.outline_modulate = UiKit.INK
	plaque.modulate = UiKit.BRASS.lightened(0.2)
	plaque.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	plaque.position = Vector3(0.0, 0.5, 0.08)
	add_child(plaque)
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.76, 0.12, 0.01)
	plate.mesh = plate_mesh
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.16, 0.1, 0.05)
	plate.material_override = plate_mat
	plate.position = Vector3(0.0, 0.5, 0.07)
	add_child(plate)
	for i in CIRCUITS.size():
		var pilot := MeshInstance3D.new()
		var bulb := SphereMesh.new()
		bulb.radius = 0.025
		bulb.height = 0.05
		bulb.radial_segments = 6
		bulb.rings = 3
		pilot.mesh = bulb
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		pilot.material_override = mat
		pilot.position = Vector3(-0.18 + 0.18 * i, 0.3, 0.09)
		add_child(pilot)
		_pilots.append(mat)
	_status = OmniLight3D.new()
	_status.omni_range = 1.6
	_status.position = Vector3(0.0, 0.3, 0.25)
	add_child(_status)
