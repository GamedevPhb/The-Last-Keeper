extends Marker3D
## A converter station: the keeper loads raw materials from the bag (`input_items`), the machine
## burns `INPUTS_PER_OUTPUT` of them per unit over `seconds_per_unit`, and finished units wait
## (up to `capacity`) until collected. One Interactable opens `ui/factory_console.gd`.
## Production runs in `_process` and freezes during story scenes, panels and outside the night,
## like the rest of the clock. Instances only differ by exports (see island_details.tscn).
## The numbers below are provisional: the game-designer balances them.

const FACTORY_CONSOLE := preload("res://ui/factory_console.gd")
const METAL := preload("res://materials/m_metal.tres")

const INPUTS_PER_OUTPUT := 3 ## raw items consumed per finished can
const OIL_SECONDS := 60.0 ## real seconds per can of oil
const FUEL_SECONDS := 75.0 ## real seconds per can of fuel
const CAPACITY := 4 ## finished cans the machine holds

@export var title := "Fábrica de óleo"
@export var input_items: PackedStringArray = ["wood", "fat", "algae"]
@export var output_item := "oil"
@export var seconds_per_unit := OIL_SECONDS
@export var inputs_per_unit := INPUTS_PER_OUTPUT
@export var capacity := CAPACITY

var stock := 0 ## raw items inside, waiting to be burned
var ready_units := 0 ## finished units waiting for collection
var progress := 0.0 ## seconds into the unit being made

var _switch: Interactable
var _console: Node
var _lamp: StandardMaterial3D


func _ready() -> void:
	_switch = Interactable.create(title, 0.0, 0.55)
	_switch.name = "Panel"
	_switch.position = Vector3(0.0, 1.0, 0.55)
	add_child(_switch)
	_switch.interacted.connect(_on_interacted)
	_build_body()
	add_to_group("saveable")
	_sync()


func _process(delta: float) -> void:
	if not GameState.in_game or GameState.finished or GameState.dead or GameState.scene_active or GameState.panel_open:
		return
	if stock < inputs_per_unit or ready_units >= capacity:
		return
	progress += delta
	if progress >= seconds_per_unit:
		progress = 0.0
		stock -= inputs_per_unit
		ready_units += 1
		GameState.play("clunk", global_position)
		_sync()


func accepts(id: String) -> bool:
	return id in input_items


## Room left for raw items: enough to fill the output buffer, no more.
func stock_room() -> int:
	return maxi((capacity - ready_units) * inputs_per_unit - stock, 0)


## Moves up to `amount` of `id` from the bag into the machine. Returns how many went in.
func deposit(id: String, amount: int) -> int:
	if not accepts(id):
		return 0
	var moved := mini(mini(amount, GameState.inventory.count(id)), stock_room())
	if moved <= 0 or not GameState.inventory.remove(id, moved):
		return 0
	stock += moved
	_sync()
	return moved


## Hands the finished units to the keeper (what does not fit drops at the feet). Returns the amount.
func collect() -> int:
	var amount := ready_units
	if amount <= 0:
		return 0
	ready_units = 0
	GameState.give(output_item, amount, global_position + Vector3(0.0, 0.5, 1.0))
	_sync()
	return amount


func progress_ratio() -> float:
	if stock < inputs_per_unit or ready_units >= capacity:
		return 0.0
	return clampf(progress / seconds_per_unit, 0.0, 1.0)


func running() -> bool:
	return stock >= inputs_per_unit and ready_units < capacity


func save_state() -> Dictionary:
	return {"stock": stock, "ready": ready_units, "progress": progress}


func load_state(data: Dictionary) -> void:
	stock = int(data.get("stock", 0))
	ready_units = int(data.get("ready", 0))
	progress = float(data.get("progress", 0.0))
	_sync()


func _on_interacted(by: Node) -> void:
	if _console == null:
		_console = FACTORY_CONSOLE.new()
		_console.factory = self
		add_child(_console)
	_console.open(by as Player)


func _sync() -> void:
	if _switch == null:
		return
	_switch.prompt = "%s (%d pronta%s)" % [title, ready_units, "" if ready_units == 1 else "s"]
	if _lamp:
		_lamp.albedo_color = Color(1.0, 0.6, 0.1) if running() else (Color(0.3, 1.0, 0.35) if ready_units > 0 else Color(0.2, 0.05, 0.04))


## Greybox machine: a metal box, a chimney and a status lamp (amber working, green ready).
func _build_body() -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	add_child(body)
	var box := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.4, 1.2, 0.8)
	box.mesh = box_mesh
	box.material_override = METAL
	box.position = Vector3(0.0, 0.6, 0.0)
	body.add_child(box)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = box_mesh.size
	shape.shape = box_shape
	shape.position = box.position
	body.add_child(shape)
	var chimney := MeshInstance3D.new()
	var chimney_mesh := CylinderMesh.new()
	chimney_mesh.top_radius = 0.1
	chimney_mesh.bottom_radius = 0.12
	chimney_mesh.height = 1.0
	chimney_mesh.radial_segments = 6
	chimney.mesh = chimney_mesh
	chimney.material_override = METAL
	chimney.position = Vector3(0.4, 1.7, 0.0)
	add_child(chimney)
	var lamp := MeshInstance3D.new()
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = Vector3(0.14, 0.14, 0.05)
	lamp.mesh = lamp_mesh
	_lamp = StandardMaterial3D.new()
	_lamp.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lamp.material_override = _lamp
	lamp.position = Vector3(-0.45, 0.95, 0.42)
	add_child(lamp)
