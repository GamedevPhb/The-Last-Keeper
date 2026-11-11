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
	["Campo de visão", "fov", 60.0, 100.0, 1.0],
]
const SWITCHES := [["Tela cheia", "fullscreen"], ["Tremor de vértices (PS1)", "jitter"]]


func _ready() -> void:
	add_theme_stylebox_override("panel", UiKit.style(Color(0.05, 0.06, 0.08, 0.96), Color(0.45, 0.38, 0.26)))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	add_child(box)
	box.add_child(UiKit.label("OPÇÕES"))
	for row: Array in SLIDERS:
		var line := HBoxContainer.new()
		var name := UiKit.label(row[0], 90)
		line.add_child(name)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(110, 10)
		slider.min_value = row[2]
		slider.max_value = row[3]
		slider.step = row[4]
		slider.value = Settings.values[row[1]]
		slider.value_changed.connect(func(value: float) -> void: Settings.set_value(row[1], value))
		line.add_child(slider)
		box.add_child(line)
	for row: Array in SWITCHES:
		var check := CheckBox.new()
		check.text = row[0]
		check.add_theme_font_size_override("font_size", UiKit.FONT_SIZE)
		check.button_pressed = Settings.values[row[1]]
		check.toggled.connect(func(on: bool) -> void: Settings.set_value(row[1], on))
		box.add_child(check)
	box.add_child(UiKit.button("Voltar", func() -> void: closed.emit()))
