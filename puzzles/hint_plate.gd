extends Node3D
## A procedure hint fixed next to its machine (tester feedback, phase 3: hints near each puzzle).
## Shows a short visible line (Label3D, readable at 320x240 from ~2 m) and, when read with the
## interact key, says the full procedure on the HUD. The local +Z faces the reader.
## `source` (optional) points at a node with `hint_title() -> String` and/or `hint_text() -> String`
## for live values (generator valve order, tide state); otherwise `title` and `text` are used.

enum Style { BRASS, CHALK, TAG }

const FONT := preload("res://ui/fonts/DejaVuSerifCondensed-Bold.ttf")
const REFRESH := 0.5 ## seconds between `hint_title()` polls

@export_multiline var title := ""
@export_multiline var text := ""
@export var prompt := "Ler a plaqueta"
@export var style := Style.BRASS
@export var plate_size := Vector2(0.8, 0.3)
@export var font_size := 24
@export var add_to_notes := false ## also copy the text to the book's ANOTAÇÕES
@export var post_height := 0.0 ## > 0: stands on a wooden post this tall (plate on top)
@export var source: NodePath

var _label: Label3D
var _read: Interactable
var _poll := 0.0


func _ready() -> void:
	if post_height > 0.0:
		_build_post()
	if style != Style.CHALK:
		_build_plate()
	_label = Label3D.new()
	_label.name = "Text"
	_label.font = FONT
	_label.font_size = font_size
	_label.pixel_size = 0.004
	_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	_label.line_spacing = -2.0
	_label.position = Vector3(0.0, post_height, 0.012)
	match style:
		Style.BRASS:
			_label.modulate = UiKit.BRASS.lightened(0.25)
			_label.outline_modulate = UiKit.INK
			_label.outline_size = 6
		Style.CHALK:
			_label.modulate = Color(0.86, 0.86, 0.8)
			_label.outline_modulate = Color(0.05, 0.05, 0.05)
			_label.outline_size = 4
		Style.TAG:
			_label.modulate = Color(0.12, 0.08, 0.05)
			_label.outline_size = 0
	add_child(_label)
	_read = Interactable.create(prompt, 0.0, clampf(minf(plate_size.x, plate_size.y) * 0.6, 0.12, 0.3))
	_read.name = "Read"
	_read.position = Vector3(0.0, post_height, 0.05)
	add_child(_read)
	_read.interacted.connect(_on_read)
	_refresh()


func _process(delta: float) -> void:
	_poll -= delta
	if _poll <= 0.0:
		_poll = REFRESH
		_refresh()


func current_text() -> String:
	var node := get_node_or_null(source)
	if node and node.has_method("hint_text"):
		return node.hint_text()
	return text


func _refresh() -> void:
	var node := get_node_or_null(source)
	_label.text = node.hint_title() if node and node.has_method("hint_title") else title


func _on_read(_by: Node) -> void:
	var body := current_text()
	if add_to_notes:
		GameState.add_note(body)
	GameState.play("paper", global_position)
	GameState.say(body)


func _build_plate() -> void:
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(plate_size.x, plate_size.y, 0.015)
	plate.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.16, 0.1, 0.05) if style == Style.BRASS else Color(0.78, 0.72, 0.56)
	plate.material_override = mat
	plate.position = Vector3(0.0, post_height, 0.0)
	add_child(plate)


func _build_post() -> void:
	var post := MeshInstance3D.new()
	post.name = "Post"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.08, post_height, 0.08)
	post.mesh = mesh
	post.material_override = load("res://materials/m_wood.tres")
	post.position = Vector3(0.0, post_height * 0.5, -0.05)
	add_child(post)
