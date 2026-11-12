class_name FuseConsole
extends "res://ui/puzzle_console.gd"
## Breaker panel: one lever per circuit with its pilot light, the generator load against
## its capacity and a warning when the generator is stopped or overloaded.
## The rule lives in `GameState` (generator + 3 circuits, capacity POWER_CAPACITY).

const CIRCUITS := ["radio", "house", "motor"]
const NAMES := {"radio": "RÁDIO", "house": "LUZ DA CASA", "motor": "MOTOR LANTERNA"}
const PLATE := "MÁXIMO 2 CIRCUITOS · DESLIGUE UM PARA LIGAR OUTRO"
const OVERLOAD_FLASH := 2.5

const ICONS := {
	"radio": [
		"............k",
		"...........kw",
		"..........kw",
		".........kw",
		".kkkkkkkkkkkkkk",
		".kdddddddddddddk",
		".kdkkkkkkdkkkdk",
		".kdkgggggdkbkdk",
		".kdkgsgsgdkkkdk",
		".kdkgggggddddk",
		".kdkkkkkkdkkkdk",
		".kdddddddkrkdk",
		".kdddddddkkkdk",
		".kkkkkkkkkkkkkk",
		"..kk.......kk",
	],
	"house": [
		"",
		".....kkkkk",
		"....kyyyyyk",
		"...kyywyyyyk",
		"..kyywyyyyyyk",
		"..kywyyyyyyyk",
		"..kyyyyyyyyyk",
		"..kyyyyyyyyyk",
		"...kyyyyyyyk",
		"....kyyyyyk",
		".....kbbbk",
		".....kdddk",
		".....kbbbk",
		".....kdddk",
		"......kkk",
	],
	"motor": [
		"",
		"......kk",
		"...k.kbbk.k",
		"..kbkkbbkkbk",
		"...kbbbbbbk",
		".kkbbkkkkbbkk",
		"kbbbkgggkbbbk",
		"kbbbkgkgkbbbk",
		".kkbkgggkbkk",
		"...kbkkkkbk",
		"..kbbbbbbbbk",
		"..kbkkbbkkbk",
		"...k.kbbk.k",
		"......kk",
	],
}

var box: Node3D

var _overload := 0.0
var _levers: Array[Lever] = []
var _meter: LoadMeter
var _warning: Label
var _hint: Label


func _build_body(body: VBoxContainer) -> void:
	_title.text = "QUADRO DE FORÇA"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in CIRCUITS.size():
		var circuit: String = CIRCUITS[i]
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 72
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 2)
		var top := HBoxContainer.new()
		top.alignment = BoxContainer.ALIGNMENT_CENTER
		top.add_theme_constant_override("separation", 4)
		top.add_child(_icon_button(i, icon(ICONS[circuit]), NAMES[circuit]))
		var lever := Lever.new()
		lever.custom_minimum_size = Vector2(14, 40)
		top.add_child(lever)
		_levers.append(lever)
		column.add_child(top)
		var caption := UiKit.label(NAMES[circuit])
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		row.add_child(column)
	body.add_child(row)

	var load_row := HBoxContainer.new()
	load_row.alignment = BoxContainer.ALIGNMENT_CENTER
	load_row.add_theme_constant_override("separation", 6)
	load_row.add_child(UiKit.label("CARGA DO GERADOR", 0, UiKit.BRASS))
	_meter = LoadMeter.new()
	_meter.custom_minimum_size = Vector2(66, 12)
	load_row.add_child(_meter)
	body.add_child(load_row)

	_warning = UiKit.label("", 250)
	_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_warning)
	_hint = UiKit.label("")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_hint)
	body.add_child(plaque(PLATE))


func _on_press(index: int, _still_held: Callable) -> void:
	var at := box.global_position if box else Vector3.INF
	if not GameState.toggle_breaker(CIRCUITS[index], at):
		_overload = OVERLOAD_FLASH


func _refresh() -> void:
	_overload = maxf(_overload - get_process_delta_time(), 0.0)
	var running: bool = GameState.generator_on
	var used: int = GameState.breakers_on()
	_header.text = "GERADOR LIGADO" if running else "GERADOR PARADO"
	_header.add_theme_color_override("font_color", UiKit.SEA if running else UiKit.BLOOD)
	for i in CIRCUITS.size():
		var on: bool = GameState.breakers[CIRCUITS[i]]
		_levers[i].on = on
		_levers[i].pilot = Lever.PILOT_POWERED if on and running else (Lever.PILOT_WAITING if on else Lever.PILOT_OFF)
		_levers[i].queue_redraw()
	_meter.used = used
	_meter.capacity = GameState.POWER_CAPACITY
	_meter.slots = CIRCUITS.size()
	_meter.alarm = _overload
	_meter.queue_redraw()
	if _overload > 0.0:
		_warning.text = "SOBRECARGA! O gerador só aguenta %d circuitos." % GameState.POWER_CAPACITY
		_warning.add_theme_color_override("font_color", UiKit.BLOOD.lightened(0.25))
	elif not running:
		_warning.text = "Gerador parado: nenhum circuito tem energia."
		_warning.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	elif used >= GameState.POWER_CAPACITY:
		_warning.text = "Carga máxima. Desligue um circuito para ligar outro."
		_warning.add_theme_color_override("font_color", UiKit.BONE)
	else:
		_warning.text = ""
	var circuit: String = CIRCUITS[_focus]
	_hint.text = "[%d] %s · %s" % [_focus + 1, NAMES[circuit], "desligar" if GameState.breakers[circuit] else "ligar"]


## A knife-switch lever with its pilot light on top.
class Lever extends Control:
	const PILOT_OFF := 0
	const PILOT_WAITING := 1 ## on, but the generator is stopped
	const PILOT_POWERED := 2
	var on := false
	var pilot := PILOT_OFF

	func _draw() -> void:
		var colors := [Color(0.18, 0.06, 0.05), Color(1.0, 0.6, 0.1), Color(0.3, 1.0, 0.35)]
		# Pilot light: a 6x6 lamp with a 1px rim.
		draw_rect(Rect2(3, 0, 8, 8), UiKit.INK)
		draw_rect(Rect2(4, 1, 6, 6), colors[pilot])
		if pilot != PILOT_OFF:
			draw_rect(Rect2(5, 2, 2, 2), Color(1, 1, 0.9))
		# Slot and handle.
		var slot := Rect2(5, 11, 4, size.y - 12)
		draw_rect(slot.grow(1), UiKit.INK)
		draw_rect(slot, Color(0.05, 0.08, 0.07))
		var knob_y := 11.0 if on else size.y - 9.0
		draw_rect(Rect2(1, knob_y, 12, 7), UiKit.INK)
		draw_rect(Rect2(2, knob_y + 1, 10, 5), UiKit.BRASS if on else UiKit.RUST.lightened(0.2))
		draw_rect(Rect2(2, knob_y + 1, 10, 1), UiKit.BRASS.lightened(0.4))


## Generator load: one cell per circuit; cells past the capacity are painted red.
class LoadMeter extends Control:
	var used := 0
	var capacity := 2
	var slots := 3
	var alarm := 0.0

	func _draw() -> void:
		var cell := (size.x - 2.0) / slots
		draw_rect(Rect2(Vector2.ZERO, size), UiKit.INK)
		for i in slots:
			var rect := Rect2(1.0 + i * cell + 1.0, 2.0, cell - 3.0, size.y - 4.0)
			var over := i >= capacity
			var color := Color(0.06, 0.1, 0.09)
			if i < used:
				color = Color(0.3, 0.85, 0.35)
			if over:
				color = UiKit.BLOOD if alarm > 0.0 and fmod(alarm, 0.4) > 0.2 else UiKit.BLOOD.darkened(0.6)
			draw_rect(rect, color)
			if over:
				draw_line(rect.position, rect.end, UiKit.INK, 1.0)
				draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.position.y), UiKit.INK, 1.0)
