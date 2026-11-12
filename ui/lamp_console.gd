class_name LampConsole
extends "res://ui/puzzle_console.gd"
## Brass panel for the lamp burner (GDD 4.1.1): five gauges, six icon actions and the
## one-line plaque. The base (`puzzle_console.gd`) handles opening, input and the HUD flag.

enum Kind { TAP, HOLD, TIMED }

const ACTIONS := [
	{"name": "ABASTECER", "kind": Kind.TIMED, "hint": "segure 1,5 s · gasta 1 lata", "sound": "lamp_fill", "every": 0.8},
	{"name": "AQUECER", "kind": Kind.HOLD, "hint": "segure · vaporizador +20/s", "sound": "lamp_heat", "every": 0.75},
	{"name": "BOMBEAR", "kind": Kind.TAP, "hint": "toque · pressão +8", "sound": "", "every": 0.0},
	{"name": "VÁLVULA", "kind": Kind.TAP, "hint": "toque · abre/fecha o queimador", "sound": "", "every": 0.0},
	{"name": "CORDA", "kind": Kind.TAP, "hint": "toque no pulso da catraca", "sound": "", "every": 0.0},
	{"name": "LENTE", "kind": Kind.TIMED, "hint": "segure 3 s · limpa a fuligem", "sound": "lamp_wipe", "every": 0.6},
]
enum { FILL, HEAT, PUMP, VALVE, WIND, CLEAN }

const PLATE := "AQUEÇA ATÉ O VERDE · PRESSÃO NO VERDE · ABRA A VÁLVULA"

## 16x16 icons, one character per pixel (see PALETTE). Short rows are padded.
const ICONS := [
	[ # oil can with spout, amber drop
		"................",
		"..............kk",
		".............kbk",
		"....kkk.....kbk.",
		"...kblbk...kbk..",
		"..kkkkkkkkkbk...",
		".kbbbbbbbbbk....",
		".kbllbbbbbdk..k.",
		".kblbbbbbbdk.kak",
		".kblbbbbbbdk.kak",
		".kblbbbbbbdk..k.",
		".kbbbbbbbbdk....",
		".kbbbbbbbbdk....",
		".kddddddddk.....",
		"..kkkkkkkkk.....",
	],
	[ # spirit blowtorch, short blue flame
		"",
		"",
		"",
		"..kkk",
		".kblbk",
		".kblbk......cB",
		".kblbkkkkkkBccB",
		".kblbddddddkcwcB",
		".kblbkkkkkkBccB",
		".kblbk......cB",
		".kbbbk",
		".kbbbk",
		".kdddk",
		".kdddk",
		"..kkk",
	],
	[ # hand pump plunger, arrow down
		"..kkkkkkkkk",
		"..kllbbbbdk",
		"..kkkkbkkkk..ww",
		"......kbk....ww",
		"......kbk....ww",
		"......kbk...wwww",
		"....kkkkkkk..ww",
		"....kbbbbbk",
		"....kblbbdk",
		"....kblbbdk",
		"....kblbbdk",
		"....kblbbdk",
		"....kbbbbdk",
		"...kkkkkkkkk",
		"...kdddddddk",
		"...kkkkkkkkk",
	],
	[ # valve handwheel
		"",
		".....kkkkkk",
		"...kkbbbbbbkk",
		"..kbbkkbbkkbbk",
		"..kbk..kbk..kbk",
		".kbk...kbk...kbk",
		".kbkkkkkllkkkkbk",
		".kbbbbbklldbbbbk",
		".kbkkkkkddkkkkbk",
		".kbk...kbk...kbk",
		"..kbk..kbk..kbk",
		"..kbbkkbbkkbbk",
		"...kkbbbbbbkk",
		".....kkkkkk",
	],
	[ # L crank over a gear
		"...........kkk",
		"..........kllk",
		"..........kbbk",
		"...........kbk",
		"...........kbk",
		"...........kbk",
		"..k.kk.kkkkkbk",
		"..kgkgkkbbbbbk",
		".kggggggkkkkk",
		"kgggkkkggk",
		".kggkllkggk",
		"kgggkllkgggk",
		".kggkkkkggk",
		"kgggggggggk",
		".kgkgkgkgk",
		"..k.k.k.k",
	],
	[ # folded cloth over a Fresnel ring
		"",
		"....kkkkkkk",
		"...kssssssk",
		"..kskkkkkksk",
		".ksksssssksk",
		".kskskkksksk",
		".ksksk.ksksk",
		".kskskkkskkwwk",
		".ksksssskwwwwwk",
		"..kskkkkwwwwwgk",
		"...ksssswwwwgk",
		"....kkkkkwwgk",
		".........kgk",
		"..........k",
	],
]

var beacon: Beacon

var _hold_time := 0.0
var _sound_left := 0.0
var _flash := 0.0
var _hint: Label
var _bar: ProgressBar
var _gauges: Array[Gauge] = []


func _ready() -> void:
	super()
	beacon.beat.connect(_on_beat)


func _initial_focus() -> int:
	return _urgent_action()


func _on_press(index: int, still_held: Callable) -> void:
	match index:
		FILL:
			if not beacon.can_refuel():
				beacon.refuel() # only warns: "Sem óleo"
				return
		PUMP:
			beacon.pump()
		VALVE:
			beacon.toggle_valve()
		WIND:
			beacon.wind()
	if ACTIONS[index].kind != Kind.TAP:
		_begin_hold(index, still_held)
		_hold_time = 0.0
		_sound_left = 0.0


func _hold_tick(delta: float) -> void:
	var action: Dictionary = ACTIONS[_held]
	_sound_left -= delta
	if _sound_left <= 0.0:
		_sound_left = action.every
		GameState.play(action.sound, beacon.global_position)
	if action.kind == Kind.HOLD:
		beacon.heat(delta)
		return
	_hold_time += delta
	if _hold_time < _hold_needed(_held):
		return
	if _held == FILL:
		beacon.refuel()
		GameState.play("clunk", beacon.global_position)
	else:
		beacon.clean()
	_release()


func _hold_needed(index: int) -> float:
	return Beacon.FILL_TIME if index == FILL else Beacon.CLEAN_TIME


## The action that fixes the gauge closest to its red zone.
func _urgent_action() -> int:
	var best: int = FILL
	var margin := INF
	var options := {
		FILL: beacon.oil - 10.0,
		PUMP: minf(beacon.pressure - Beacon.FLAME_MIN_PRESSURE, Beacon.SAFETY_PRESSURE - beacon.pressure),
		WIND: beacon.wound - 15.0,
		CLEAN: (100.0 - beacon.dirt) - Beacon.MIN_RANGE * 100.0,
	}
	if not beacon.lit:
		options[HEAT] = beacon.temp - 20.0
	for index: int in options:
		if options[index] < margin:
			margin = options[index]
			best = index
	if not beacon.lit and margin > 0.0 and beacon.temp >= Beacon.TEMP_GREEN and beacon.pressure_in_green():
		best = VALVE
	return best


func _on_beat() -> void:
	if not visible:
		return
	_flash = 1.0
	GameState.play("lamp_beat", beacon.global_position)


# ---- Layout

func _build_body(box: VBoxContainer) -> void:
	_title.text = "CONSOLE DA LÂMPADA"
	var dials := HBoxContainer.new()
	dials.add_theme_constant_override("separation", 5)
	dials.alignment = BoxContainer.ALIGNMENT_CENTER
	for gauge_name in ["ÓLEO", "TEMP", "PRESSÃO", "CORDA", "LENTE"]:
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 50
		column.add_theme_constant_override("separation", 1)
		var gauge := Gauge.new()
		gauge.custom_minimum_size = Vector2(14, 52)
		gauge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(gauge)
		var caption := UiKit.label(gauge_name)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		dials.add_child(column)
		_gauges.append(gauge)
	box.add_child(dials)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in ACTIONS.size():
		row.add_child(_icon_button(i, icon(ICONS[i]), ACTIONS[i].name))
	box.add_child(row)

	_hint = UiKit.label("")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hint)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(270, 3)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	var groove := UiKit.style(UiKit.INK, UiKit.RUST)
	groove.set_content_margin_all(0)
	_bar.add_theme_stylebox_override("background", groove)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiKit.BRASS
	_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(_bar)
	box.add_child(plaque(PLATE))


func _refresh() -> void:
	_header.text = beacon.status_text()
	_header.add_theme_color_override("font_color", UiKit.SEA if beacon.lit else (UiKit.BLOOD if beacon.valve_lock > 0.0 else UiKit.BONE))
	var low := beacon.green_low()
	var high := beacon.green_high()
	_gauges[0].setup(beacon.oil, Vector2(30, 100), [Vector2(0, 10)])
	_gauges[1].setup(beacon.temp, Vector2(Beacon.TEMP_GREEN, 100), [Vector2(0, 20)])
	_gauges[2].setup(beacon.pressure, Vector2(low, high), [Vector2(0, Beacon.FLAME_MIN_PRESSURE), Vector2(Beacon.SAFETY_PRESSURE, 100)], beacon.boost_from())
	_gauges[3].setup(beacon.wound, Vector2(40, 100), [Vector2(0, 15)])
	_gauges[4].setup(100.0 - beacon.dirt, Vector2(70, 100), [Vector2(0, Beacon.MIN_RANGE * 100.0)])
	_gauges[3].flash = _flash
	_flash = maxf(_flash - get_process_delta_time() * 4.0, 0.0)
	for i in _buttons.size():
		var tint := Color.WHITE
		if i == VALVE and beacon.valve_open:
			tint = Color(0.75, 1.0, 0.75)
		elif i == VALVE and beacon.valve_lock > 0.0:
			tint = Color(0.8, 0.4, 0.35)
		elif i == WIND:
			tint = Color.WHITE.lerp(Color(1.3, 1.2, 0.8), _flash)
		elif i == FILL and not beacon.can_refuel():
			tint = Color(0.55, 0.55, 0.55)
		_buttons[i].modulate = tint
	var action: Dictionary = ACTIONS[_focus]
	_hint.text = "[%d] %s · %s" % [_focus + 1, action.name, action.hint]
	if _held >= 0 and ACTIONS[_held].kind == Kind.TIMED:
		_bar.value = _hold_time / _hold_needed(_held)
	elif _held == HEAT:
		_bar.value = beacon.temp / 100.0
	else:
		_bar.value = 0.0


## A vertical brass gauge with painted green and red zones and a bone needle.
class Gauge extends Control:
	var value := 0.0
	var green := Vector2(70, 100)
	var reds: Array = []
	var boost := -1.0
	var flash := 0.0

	func setup(new_value: float, new_green: Vector2, new_reds: Array, new_boost := -1.0) -> void:
		value = new_value
		green = new_green
		reds = new_reds
		boost = new_boost
		queue_redraw()

	func _y(v: float) -> float:
		return 1.0 + (size.y - 2.0) * (1.0 - clampf(v, 0.0, 100.0) / 100.0)

	func _band(from: float, to: float, color: Color) -> void:
		var top := _y(to)
		draw_rect(Rect2(1, top, 3, _y(from) - top), color)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UiKit.INK)
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), Color(0.05, 0.09, 0.08))
		_band(green.x, green.y, Color(0.2, 0.55, 0.25))
		if boost >= 0.0:
			_band(boost, green.y, Color(0.45, 0.8, 0.4))
		var in_red := false
		for zone: Vector2 in reds:
			_band(zone.x, zone.y, UiKit.BLOOD)
			in_red = in_red or (value >= zone.x and value <= zone.y)
		var top := _y(value)
		var fill_color := UiKit.BLOOD.lightened(0.15) if in_red else UiKit.BRASS.darkened(0.15)
		draw_rect(Rect2(5, top, size.x - 6, size.y - 1 - top), fill_color)
		draw_rect(Rect2(1, top - 1, size.x - 2, 2), UiKit.BONE)
		var edge := UiKit.BRASS.lerp(Color(1, 0.95, 0.7), flash) if flash > 0.0 else UiKit.RUST
		draw_rect(Rect2(Vector2.ZERO, size), edge, false, 1.0)
