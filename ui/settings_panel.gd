class_name SettingsPanel
extends PanelContainer
## Options: volumes, brightness, sensitivity, field of view and a few switches.
## Full screen (anchored to the viewport, opaque): title on top, a scrolling list in the middle
## (one column, two on wide screens or with touch) and the Voltar button pinned at the bottom.
## Every change applies and saves at once, so there is no separate Apply button.

signal closed

const SLIDERS := [
	["Volume geral", "master", 0.0, 1.0, 0.05],
	["Música", "music", 0.0, 1.0, 0.05],
	["Efeitos", "sfx", 0.0, 1.0, 0.05],
	["Brilho", "brightness", 0.6, 1.8, 0.05],
	["Mouse", "mouse", 0.001, 0.006, 0.0002],
	["Analógico", "stick", 1.0, 6.0, 0.2],
	["Toque (olhar)", "touch_look", 0.004, 0.03, 0.001],
	["Campo de visão", "fov", 60.0, 100.0, 1.0],
	["Filtro CRT", "crt", 0.0, 1.0, 0.1],
	["Granulado", "grain", 0.0, 1.0, 0.1],
]
const SWITCHES := [["Tela cheia", "fullscreen"], ["Tremor de vértices (PS1)", "jitter"], ["Mostrar mãos", "hands"]]
const TOUCH_MODES := ["Auto", "Ligados", "Desligados"]

## Layout the panel was built for, to rebuild when touch or the viewport shape changes.
var _built_key := ""
var _first: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", UiKit.style(Color(0.035, 0.06, 0.055, 1.0), UiKit.BRASS))
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	Settings.applied.connect(_on_applied)
	get_viewport().size_changed.connect(_on_applied)
	visibility_changed.connect(_on_visibility)


func _layout_key() -> String:
	return "%s%s" % [TouchControls.enabled, _columns()]


func _columns() -> int:
	return 2 if TouchControls.enabled or get_viewport().get_visible_rect().size.x >= 400.0 else 1


## Switching the touch controls or the viewport shape changes the layout; rebuild once the click that did it is over.
func _on_applied() -> void:
	if _layout_key() != _built_key:
		_build.call_deferred()


func _on_visibility() -> void:
	if visible and _first:
		_focus_first.call_deferred()


func _focus_first() -> void:
	if visible and is_inside_tree() and is_instance_valid(_first) and _first.is_inside_tree():
		_first.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built_key = _layout_key()
	var touch := TouchControls.enabled
	var columns := _columns()
	var row_height := 24.0 if touch else 10.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	add_child(box)
	box.add_child(UiKit.heading("OPÇÕES"))
	box.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 24)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	box.add_child(scroll)
	var inset := MarginContainer.new()
	inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inset.add_theme_constant_override("margin_right", 4)
	scroll.add_child(inset)
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 1)
	inset.add_child(grid)
	_first = null
	for row: Array in SLIDERS:
		var line := HBoxContainer.new()
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(UiKit.label(row[0], 70 if columns == 2 else 90))
		var slider := HSlider.new()
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.custom_minimum_size = Vector2(40, row_height)
		slider.min_value = row[2]
		slider.max_value = row[3]
		slider.step = row[4]
		slider.value = Settings.values[row[1]]
		slider.value_changed.connect(func(value: float) -> void: Settings.set_value(row[1], value))
		line.add_child(slider)
		grid.add_child(line)
		if _first == null:
			_first = slider
	for row: Array in SWITCHES:
		var check := CheckBox.new()
		check.text = row[0]
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
		check.button_pressed = Settings.values[row[1]]
		check.toggled.connect(func(on: bool) -> void: Settings.set_value(row[1], on))
		grid.add_child(check)
	var fps := Button.new()
	fps.text = "Quadros: %d fps" % int(Settings.values["fps"])
	fps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fps.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
	fps.pressed.connect(func() -> void:
		Settings.set_value("fps", 60 if int(Settings.values["fps"]) == 30 else 30)
		fps.text = "Quadros: %d fps" % int(Settings.values["fps"]))
	grid.add_child(fps)
	var mode := Button.new()
	mode.text = _touch_text()
	mode.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
	mode.pressed.connect(func() -> void:
		Settings.set_value("touch", (int(Settings.values["touch"]) + 1) % TOUCH_MODES.size())
		mode.text = _touch_text())
	grid.add_child(mode)
	box.add_child(HSeparator.new())
	var back := UiKit.button("Voltar", func() -> void: closed.emit())
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size.x = 90
	box.add_child(back)
	if visible and _first:
		_focus_first.call_deferred()


func _touch_text() -> String:
	var mode: String = TOUCH_MODES[clampi(int(Settings.values["touch"]), 0, TOUCH_MODES.size() - 1)]
	return "Controles de toque: %s" % mode
