extends Control
## Opening sequence: "uma produção de" VKS Games, then "um oferecimento" Porto Indie, then the main menu.

const MENU := "res://ui/main_menu.tscn"
const SLIDES := [
	["UMA PRODUÇÃO DE", "res://ui/intro/vks.png", 130.0],
	["UM OFERECIMENTO", "res://ui/intro/porto_indie.svg", 150.0],
]
const FADE := 1.0
const HOLD := 1.6

var _caption: Label
var _logo: TextureRect
var _done := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 14)
	add_child(column)
	_caption = UiKit.label("", 0, Color(0.7, 0.72, 0.7))
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_caption)
	_logo = TextureRect.new()
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	column.add_child(_logo)
	column.modulate.a = 0.0
	_play(column)


func _unhandled_input(event: InputEvent) -> void:
	if not _done and event.is_pressed() and not event.is_echo():
		_finish()


func _play(column: Control) -> void:
	var tween := create_tween()
	for slide: Array in SLIDES:
		tween.tween_callback(_show.bind(slide))
		tween.tween_property(column, "modulate:a", 1.0, FADE)
		tween.tween_interval(HOLD)
		tween.tween_property(column, "modulate:a", 0.0, FADE)
		tween.tween_interval(0.4)
	tween.tween_callback(_finish)


func _show(slide: Array) -> void:
	_caption.text = slide[0]
	var texture: Texture2D = load(slide[1])
	_logo.texture = texture
	var width: float = slide[2]
	_logo.custom_minimum_size = Vector2(width, width * texture.get_height() / texture.get_width())


func _finish() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file(MENU)
