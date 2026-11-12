class_name SettingsPanel
extends PanelContainer
## Options: volumes, brightness, sensitivity, field of view and a few switches.

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
]
const SWITCHES := [["Tela cheia", "fullscreen"], ["Tremor de vértices (PS1)", "jitter"]]
const TOUCH_MODES := ["Auto", "Ligados", "Desligados"]

## Layout built for touch (two columns, 24 px rows) or for mouse/pad (one column).
var _built_touch := false


func _ready() -> void:
	_build()
	Settings.applied.connect(_on_applied)


## Switching the touch controls changes the layout; rebuild once the click that did it is over.
func _on_applied() -> void:
	if TouchControls.enabled != _built_touch:
		_build.call_deferred()


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_built_touch = TouchControls.enabled
	var touch := _built_touch
	var row_height := 24.0 if touch else 8.0
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 1)
	add_child(box)
	var sliders := box
	var side := box
	if touch:
		# 320x240 cannot fit nine 24 px rows: sliders on the left, the rest on the right.
		var columns := HBoxContainer.new()
		columns.add_theme_constant_override("separation", 6)
		box.add_child(columns)
		sliders = VBoxContainer.new()
		sliders.add_theme_constant_override("separation", 0)
		columns.add_child(sliders)
		side = VBoxContainer.new()
		side.add_theme_constant_override("separation", 2)
		columns.add_child(side)
	side.add_child(UiKit.heading("OPÇÕES"))
	side.add_child(HSeparator.new())
	for row: Array in SLIDERS:
		var line := HBoxContainer.new()
		var caption := UiKit.label(row[0], 66 if touch else 84)
		line.add_child(caption)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(84 if touch else 100, row_height)
		slider.min_value = row[2]
		slider.max_value = row[3]
		slider.step = row[4]
		slider.value = Settings.values[row[1]]
		slider.value_changed.connect(func(value: float) -> void: Settings.set_value(row[1], value))
		line.add_child(slider)
		sliders.add_child(line)
	for row: Array in SWITCHES:
		var check := CheckBox.new()
		check.text = row[0]
		check.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
		check.button_pressed = Settings.values[row[1]]
		check.toggled.connect(func(on: bool) -> void: Settings.set_value(row[1], on))
		side.add_child(check)
	var mode := Button.new()
	mode.text = _touch_text()
	mode.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
	mode.pressed.connect(func() -> void:
		Settings.set_value("touch", (int(Settings.values["touch"]) + 1) % TOUCH_MODES.size())
		mode.text = _touch_text())
	side.add_child(mode)
	side.add_child(UiKit.button("Voltar", func() -> void: closed.emit()))


func _touch_text() -> String:
	var mode: String = TOUCH_MODES[clampi(int(Settings.values["touch"]), 0, TOUCH_MODES.size() - 1)]
	return ("Toque: %s" if _built_touch else "Controles de toque: %s") % mode
