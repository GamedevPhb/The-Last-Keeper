class_name RadioPanel
extends "res://ui/puzzle_console.gd"
## The portable radio's screen (GDD 4.8), opened with R / d-pad up. It relays the house radio:
## the call, its frequency, name, heading and declared cargo, the last log lines. ATENDER makes
## contact and buys 30 s once, RECUSAR is final, REPETIR re-rolls the static (4 s, 5 battery).
## Only the desk can authorise a docking. Signal: clean up to 20 m from the desk (and at the
## top of the lighthouse), letters lost to '#' from 20 to 40 m, no data beyond.

enum { ANSWER, AUTHORIZE, REFUSE, REPEAT }

const CLEAN_RANGE := 20.0
const MAX_RANGE := 40.0
const TOWER_TOP := 14.0
const REPEAT_TIME := 4.0
const REPEAT_COST := 5.0
const ACTIONS := ["ATENDER", "AUTORIZAR", "RECUSAR", "REPETIR"]
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
	[ # green check
		"",
		"",
		"",
		"............kk",
		"...........kssk",
		"..........kssk",
		".........kssk",
		"..kk....kssk",
		".kssk..kssk",
		"..kssk.kssk",
		"...kssksk",
		"....kssk",
		".....kk",
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
var _bars: TextureRect
var _batt: TextureRect
var _phone: TextureRect
var _clock: Label
var _bars_n := -1
var _batt_n := -1

const CASE := Color(0.27, 0.29, 0.3)
const CASE_DARK := Color(0.1, 0.11, 0.12)
const LCD_BG := Color(0.16, 0.22, 0.17)
const LCD_FG := Color(0.62, 0.86, 0.6)
const PHONE_ICON := [
	"", "kkk..kkk", "kkkkkkkk", "kk....kk", "kk....kk", "kk....kk", "kk....kk",
]


static func _device_box(fill: Color, border: Color, margin := 4) -> StyleBoxFlat:
	var box := UiKit.style(fill, border)
	box.set_corner_radius_all(3)
	box.set_border_width_all(2)
	box.set_content_margin_all(margin)
	box.anti_aliasing = false
	return box


## Signal bars (0-4) or battery segments (0-5) as a tiny pixel texture.
static func _meter(count: int, total: int, step: int, color: Color) -> ImageTexture:
	var img := Image.create(total * step + 1, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in total:
		var h := 2 + 2 * i if total == 4 else 6
		for x in step - 1:
			for y in h:
				img.set_pixel(i * step + x + 1, 7 - y, color if i < count else Color(color, 0.25))
	return ImageTexture.create_from_image(img)


func _build_body(body: VBoxContainer) -> void:
	_title.text = "PORTÁTIL"
	_title.add_theme_color_override("font_color", Color(0.75, 0.78, 0.78))
	_header.add_theme_color_override("font_color", LCD_FG)
	_panel.add_theme_stylebox_override("panel", _device_box(CASE, CASE_DARK, 6))
	_normal_box = _device_box(Color(0.36, 0.38, 0.39), CASE_DARK, 2)
	_focus_box = _device_box(Color(0.5, 0.56, 0.5), Color(0.62, 0.86, 0.6), 2)
	# Status bar: signal, battery, game clock, ringing handset.
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 6)
	_bars = _status_icon()
	_batt = _status_icon()
	_phone = _status_icon()
	_phone.texture = icon(PHONE_ICON, 8)
	_clock = UiKit.label("", 0, LCD_FG)
	_clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for node in [_bars, _batt, _phone, _clock]:
		status.add_child(node)
	var status_box := _device_box(LCD_BG.darkened(0.3), CASE_DARK, 2)
	var status_panel := PanelContainer.new()
	status_panel.add_theme_stylebox_override("panel", status_box)
	status_panel.add_child(status)
	body.add_child(status_panel)
	_screen = UiKit.label("", 250, LCD_FG)
	_screen.custom_minimum_size.y = 96
	_screen.add_theme_stylebox_override("normal", _device_box(LCD_BG, CASE_DARK, 4))
	var grid := Control.new()
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.draw.connect(func() -> void:
		for y in range(0, int(grid.size.y), 2):
			grid.draw_line(Vector2(0, y), Vector2(grid.size.x, y), Color(0, 0, 0, 0.14)))
	_screen.add_child(grid)
	body.add_child(_screen)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	for i in ACTIONS.size():
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 1)
		cell.add_child(_icon_button(i, icon(ICONS[i]), ACTIONS[i]))
		var tag := UiKit.label(ACTIONS[i], 0, Color(0.75, 0.78, 0.78))
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(tag)
		row.add_child(cell)
	body.add_child(row)
	_hint = UiKit.label("")
	_hint.visible = false
	body.add_child(_hint)


func _status_icon() -> TextureRect:
	var rect := TextureRect.new()
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.custom_minimum_size = Vector2(22, 16)
	return rect


func _help_text() -> String:
	return "[1-4] ações  [A/D] foco  [E/Espaço] usar  [R/Q/Esc] fechar"


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
		AUTHORIZE:
			desk.authorize_remote()
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
	_header.text = "%d%%" % roundi(GameState.radio_battery)
	_header.add_theme_color_override("font_color", UiKit.BLOOD if GameState.radio_battery < 20.0 else LCD_FG)
	var loss := signal_loss()
	var bars := 4 if loss <= 0.0 else (0 if loss >= 1.0 else (2 if loss < 0.45 else 1))
	if bars != _bars_n:
		_bars_n = bars
		_bars.texture = _meter(bars, 4, 3, LCD_FG)
	var segs := ceili(GameState.radio_battery / 20.0)
	if segs != _batt_n:
		_batt_n = segs
		_batt.texture = _meter(segs, 5, 3, UiKit.BLOOD if segs <= 1 else LCD_FG)
	_phone.modulate = Color(1, 1, 1, 1.0 if GameState.ringing and int(Time.get_ticks_msec() / 400) % 2 == 0 else (0.0 if GameState.ringing else 0.2))
	_clock.text = GameState.clock_text()
	_screen.text = screen_text()


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
		lines.append("CHAMADA ENTRANDO · ESPERA %d s" % ceili(ship.left))
	elif _repeat_left > 0.0:
		lines.append("... REPETINDO (%d s)" % ceili(_repeat_left))
	elif ship.status != "contact":
		lines.append("%sCHAMADA TOCANDO · %s" % ["(!) " if GameState.ringing and int(Time.get_ticks_msec() / 400) % 2 == 0 else "", desk.freq_text()])
		lines.append("NOME  ????")
		lines.append("RUMO  " + ship.get("bearing", "?"))
		lines.append("CARGA ????")
		lines.append("ESPERA %d s · ATENDA PARA OUVIR" % ceili(ship.left))
	else:
		lines.append("CHAMADA EM CONTATO · %s" % desk.freq_text())
		lines.append("\"AQUI É O %s. PEDIMOS ATRACAÇÃO.\"" % garble(ship.call, loss, 1))
		lines.append("RUMO  " + ship.get("bearing", "?"))
		lines.append("CARGA " + garble(ship.claim, loss, 2))
		lines.append("ESPERA %d s · COMPARE COM O LIVRO" % ceili(ship.left))
		lines.append("AUTORIZE OU RECUSE")
	lines.append("")
	for entry in GameState.call_log.slice(0, 3):
		lines.append(entry)
	return "\n".join(lines)
