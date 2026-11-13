extends Marker3D
## Base of the night-2+ structures (fishing, workshop, garden, watchtower, fence). A Marker3D with
## one Interactable; hidden and inert until `GameState.unlocked(unlock_id)`. Per-night uses are
## counted in `uses` (reset by a new night; the island reloads with it). Subclasses override
## `_use()` and may set `per_night`. Numbers are provisional (game-designer).

@export var unlock_id := ""
@export var title := "Estação"
@export var hold_time := 0.0
@export var per_night := 1 ## uses per night (0 = unlimited)

var uses := 0
var uses_night := 0 ## the night `uses` refers to

var _switch: Interactable
var _body: Node3D


func _ready() -> void:
	_switch = Interactable.create(title, hold_time, 0.7)
	_switch.name = "Use"
	_switch.position = Vector3(0.0, 0.8, 0.0)
	add_child(_switch)
	_switch.interacted.connect(_on_interacted)
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	_build_body(_body)
	add_to_group("saveable")
	_apply()


func _process(_delta: float) -> void:
	if GameState.unlocked(unlock_id) != _body.visible or _switch.enabled != _can_use():
		_apply()


func is_open() -> bool:
	return GameState.unlocked(unlock_id)


func uses_left() -> int:
	if per_night <= 0:
		return 99
	return per_night if uses_night != GameState.night else maxi(per_night - uses, 0)


## Counts one use tonight.
func spend_use() -> void:
	if uses_night != GameState.night:
		uses_night = GameState.night
		uses = 0
	uses += 1
	_apply()


func _can_use() -> bool:
	return is_open() and uses_left() > 0


func _apply() -> void:
	if _switch == null:
		return
	_body.visible = is_open()
	_switch.enabled = _can_use()
	_switch.prompt = _prompt()


func _prompt() -> String:
	return title


func _on_interacted(by: Node) -> void:
	if _can_use():
		_use(by)
	_apply()


func _use(_by: Node) -> void:
	pass


func _build_body(_root: Node3D) -> void:
	pass


## Greybox helper: a box of `size` at `at`, optionally solid.
func _box(root: Node3D, size: Vector3, at: Vector3, material: Material, solid := true) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	mesh.position = at
	root.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		body.position = at
		body.add_child(shape)
		root.add_child(body)


func save_state() -> Dictionary:
	return {"uses": uses, "uses_night": uses_night}


func load_state(data: Dictionary) -> void:
	uses = int(data.get("uses", 0))
	uses_night = int(data.get("uses_night", 0))
	_apply()
