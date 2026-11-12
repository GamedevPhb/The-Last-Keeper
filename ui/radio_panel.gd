class_name RadioPanel
extends "res://ui/puzzle_console.gd"
## The portable radio's screen (GDD 4.8), opened with R / d-pad up. It relays the house radio:
## the call, its frequency, name, heading and declared cargo, the last log lines. ATENDER makes
## contact and buys 30 s once, RECUSAR is final, REPETIR re-rolls the static (4 s, 5 battery).
## Only the desk can authorise a docking. Signal: clean up to 20 m from the desk (and at the
## top of the lighthouse), letters lost to '#' from 20 to 40 m, no data beyond.

enum { ANSWER, REFUSE, REPEAT }

const CLEAN_RANGE := 20.0
const MAX_RANGE := 40.0
const TOWER_TOP := 14.0
const REPEAT_TIME := 4.0
const REPEAT_COST := 5.0
const ACTIONS := ["ATENDER", "RECUSAR", "REPETIR"]
const ICONS := [
	[ # handset
		"",
		"",
		"..kkk......kkk",
		".ksssk....ksssk",
		".ksssk....ksssk",
		".kssskkkkkksssk",
		"..kssssssssssk",
		"...kkkkkkkkkk",
		"",
		"....kkkkkkk",
		"...kgggggggk",
		"...kgkgkgkgk",
		"...kgggggggk",
		"...kkkkkkkkk",
	],
	[ # red cross
		"",
		"",
		"..kk......kk",
		".krrk....krrk",
		"..krrk..krrk",
		"...krrkkrrk",
		"....krrrrk",
		".....krrk",
		"....krrrrk",
		"...krrkkrrk",
		"..krrk..krrk",
		".krrk....krrk",
		"..kk......kk",
	],
	[ # circular arrow
		"",
		"....kkkkk",
		"...kbbbbbk.k",
		"..kbkkkkkbkbk",
		".kbk.....kbbk",
		".kbk....kbbbk",
		".kbk.....kkkk",
		".kbk",
		".kbk.......kk",
		".kbbk.....kbk",
		"..kbbkkkkkbk",
		"...kbbbbbbk",
		"....kkkkkk",
	],
]

var _screen: Label
var _repeat_left := 0.0
var _repeats := 0
var _hint: Label


func _build_body(body: VBoxContainer) -> void:
	_title.text = "RÁDIO PORTÁTIL"
	_screen = UiKit.label("", 250, Color(0.55, 0.95, 0.6))
	_screen.custom_minimum_size.y = 96
	var face := UiKit.style(Color(0.02, 0.06, 0.03), UiKit.RUST)
	face.set_content_margin_all(4)
	_screen.add_theme_stylebox_override("normal", face)
	body.add_child(_screen)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	for i in ACTIONS.size():
		row.add_child(_icon_button(i, icon(ICONS[i]), ACTIONS[i]))
	body.add_child(row)
	_hint = UiKit.label("")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_hint)
	body.add_child(plaque("SÓ A CASA AUTORIZA · COMPARE A CARGA COM O LIVRO"))


func _help_text() -> String:
	return "[1-3] ações  [A/D] foco  [E/Espaço] usar  [R/Q/Esc] fechar"


func open(by: Player = null) -> void:
	if GameState.radio_battery <= 0.0:
		GameState.say("O portátil está sem bateria. Recarregue na base, na casa.")
		return
	super(by)
	GameState.radio_open = true


func close() -> void:
	GameState.radio_open = false
	super()


func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		close()
		get_viewport().set_input_as_handled()
		return
	super(event)


func _desk() -> Node3D:
	return get_tree().get_first_node_in_group("radio_desk") as Node3D


## 0 = clean, 1 = no data; in between, the share of letters lost grows with distance.
func signal_loss() -> float:
	var desk = _desk()
	if desk == null or GameState.player == null:
		return 0.0
	if GameState.player.global_position.y > TOWER_TOP:
		return 0.0
	var distance := GameState.player.global_position.distance_to(desk.global_position)
	if distance <= CLEAN_RANGE:
		return 0.0
	if distance > MAX_RANGE:
		return 1.0
	return lerpf(0.3, 0.6, (distance - CLEAN_RANGE) / (MAX_RANGE - CLEAN_RANGE))


## Replaces a share of the letters with '#', the same way until the next REPETIR.
func garble(text: String, loss: float, salt: int) -> String:
	if loss <= 0.0:
		return text
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.active_call.get("seed", 0), _repeats, salt])
	var out := ""
	for c in text:
		out += "#" if c != " " and rng.randf() < loss else c
	return out


func _on_press(index: int, _still_held: Callable) -> void:
	var desk = _desk()
	if not GameState.powered("radio") or desk == null:
		GameState.play("static")
		return
	if signal_loss() >= 1.0:
		GameState.say("Longe demais da casa: o portátil não alcança.")
		return
	match index:
		ANSWER:
			if desk.answer_remote():
				GameState.play("radio_beep")
		REFUSE:
			desk.refuse_remote()
		REPEAT:
			if _repeat_left <= 0.0 and not GameState.active_call.is_empty():
				GameState.radio_battery = maxf(GameState.radio_battery - REPEAT_COST, 0.0)
				_repeat_left = REPEAT_TIME
				GameState.play("static")


func _refresh() -> void:
	if _repeat_left > 0.0:
		_repeat_left -= get_process_delta_time()
		if _repeat_left <= 0.0:
			_repeats += 1
	if GameState.radio_battery <= 0.0:
		close()
		GameState.say("O portátil apagou: sem bateria.")
		return
	_header.text = "BAT %d%%" % roundi(GameState.radio_battery)
	_header.add_theme_color_override("font_color", UiKit.BLOOD if GameState.radio_battery < 20.0 else UiKit.SEA)
	_screen.text = screen_text()
	_hint.text = "[%d] %s" % [_focus + 1, ACTIONS[_focus]]


func screen_text() -> String:
	var lines: Array[String] = []
	var ship: Dictionary = GameState.active_call
	var desk = _desk()
	var loss := signal_loss()
	if not GameState.powered("radio") or desk == null:
		lines.append("SEM PORTADORA")
	elif ship.is_empty():
		lines.append("SEM CHAMADAS. AGUARDANDO.")
	elif loss >= 1.0:
		lines.append("CHAMADA ENTRANDO")
	elif _repeat_left > 0.0:
		lines.append("... REPETINDO (%d s)" % ceili(_repeat_left))
	else:
		lines.append("CHAMADA %s · %s" % ["EM CONTATO" if ship.status == "contact" else "ENTRANDO", desk.freq_text()])
		lines.append("NOME  " + garble(ship.call, loss, 1))
		lines.append("RUMO  " + ship.get("bearing", "?"))
		lines.append("CARGA " + garble(ship.claim, loss, 2))
		lines.append("ESPERA %d s%s" % [ceili(ship.left), "" if ship.get("extended", false) else " · atender dá +30 s"])
	lines.append("")
	for entry in GameState.call_log.slice(0, 3):
		lines.append(entry)
	return "\n".join(lines)
