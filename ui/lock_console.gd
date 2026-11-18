class_name LockConsole
extends "res://ui/puzzle_console.gd"
## Cellar padlock: three brass dials, 0-9. Up/down (W/S, d-pad, wheel buttons) turn the focused
## dial, left/right (A/D) change dial, interact (E / Square / Space) confirms, Esc / Q / Circle cancel.
## The padlock itself (`puzzles/cellar_lock.gd`) owns the code and the pantry.

const PLATE := "←/→ ESCOLHE O DÍGITO · ↑/↓ GIRA · E CONFIRMA · ESC SAI"
const DIGIT_SIZE := 20
const SUCCESS_TIME := 0.7
const WRONG_TIME := 0.9

var lock: Node ## cellar_lock.gd

var _digits := [0, 0, 0]
var _digit_labels: Array[Label] = []
var _carets: Array[Label] = [] ## "DÍGITO n" over each dial, lit on the selected one
var _status: Label
var _wrong := 0.0
var _success := 0.0


func _build_body(body: VBoxContainer) -> void:
	_title.text = "CADEADO DO PORÃO"
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in 3:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		var caret := UiKit.label("", 0, UiKit.BONE)
		caret.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caret)
		_carets.append(caret)
		column.add_child(_step_button("▲", i, 1))
		var digit := UiKit.label("0", 0, UiKit.BONE)
		digit.add_theme_font_size_override("font_size", DIGIT_SIZE)
		digit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		digit.custom_minimum_size = Vector2(36, 28)
		digit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		digit.add_theme_stylebox_override("normal", UiKit.style(Color(0.05, 0.07, 0.06), UiKit.RUST))
		column.add_child(digit)
		_digit_labels.append(digit)
		column.add_child(_step_button("▼", i, -1))
		row.add_child(column)
	body.add_child(row)
	_status = UiKit.label("", 250)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)
	body.add_child(UiKit.button("CONFIRMAR", confirm))
	body.add_child(plaque(PLATE))


func _step_button(text: String, dial: int, step: int) -> Button:
	var button := UiKit.button(text, func() -> void: turn(dial, step))
	button.focus_mode = Control.FOCUS_NONE
	return button


func _action_count() -> int:
	return 3


func _help_text() -> String:
	return "[A/D ←/→] dígito  [W/S ↑/↓] girar  [E] confirmar  [Esc] sair"


func open(by: Player = null) -> void:
	_digits = lock.digits() if lock else [0, 0, 0]
	_wrong = 0.0
	_success = 0.0
	super.open(by)


## Changes one dial by `step` (wraps 0-9) and remembers the position in the padlock.
func turn(dial: int, step: int) -> void:
	if _success > 0.0:
		return
	_focus = dial
	_digits[dial] = posmod(_digits[dial] + step, 10)
	_wrong = 0.0
	GameState.play("click")
	if lock:
		lock.set_digits(_digits)


## Tries the dials: opens the hatch (after a short beat) or clacks and turns red.
func confirm() -> void:
	if _success > 0.0 or _wrong > 0.0:
		return
	if _digits == lock.CODE:
		_success = SUCCESS_TIME
		GameState.play("switch")
	else:
		_wrong = WRONG_TIME
		GameState.play("click")
		GameState.say("O cadeado não abre. Os números estão escritos pela ilha.")


func _on_press(index: int, _still_held: Callable) -> void:
	turn(index, 1) # keys 1-3 spin the matching dial


func _input(event: InputEvent) -> void:
	if not visible or event is InputEventMouse:
		return
	if _success > 0.0:
		get_viewport().set_input_as_handled()
		return
	var step := 0
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		step = 1
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		step = -1
	if step != 0:
		turn(_focus, step)
		get_viewport().set_input_as_handled()
		return
	for action_name in ["interact", "ui_accept", "jump"]:
		if event.is_action_pressed(action_name):
			confirm()
			get_viewport().set_input_as_handled()
			return
	super._input(event)


func _refresh() -> void:
	_wrong = maxf(_wrong - get_process_delta_time(), 0.0)
	if _success > 0.0:
		_success -= get_process_delta_time()
		if _success <= 0.0:
			var padlock := lock
			close()
			padlock.try_code(_digits)
			return
	for i in 3:
		_digit_labels[i].text = str(_digits[i])
		var color := UiKit.BONE
		if _success > 0.0:
			color = Color(0.3, 1.0, 0.35)
		elif _wrong > 0.0:
			color = UiKit.BLOOD.lightened(0.25)
		elif i == _focus:
			color = UiKit.BRASS
		_digit_labels[i].add_theme_color_override("font_color", color)
		_digit_labels[i].add_theme_stylebox_override("normal",
			UiKit.style(Color(0.05, 0.07, 0.06), UiKit.BRASS if i == _focus else UiKit.RUST))
		_carets[i].text = "▼ %d ▼" % (i + 1) if i == _focus else str(i + 1)
		_carets[i].add_theme_color_override("font_color", UiKit.BRASS if i == _focus else Color(0.6, 0.62, 0.58))
	if _success > 0.0:
		_header.text = "ABERTO"
		_header.add_theme_color_override("font_color", UiKit.SEA)
		_status.text = "Clique. O trinco cede."
	elif _wrong > 0.0:
		_header.text = "TRAVADO"
		_header.add_theme_color_override("font_color", UiKit.BLOOD)
		_status.text = "Não abre. Combinação errada."
	else:
		_header.text = "TRAVADO"
		_header.add_theme_color_override("font_color", UiKit.BRASS)
		_status.text = "Dígito %d de 3 selecionado" % (_focus + 1)
