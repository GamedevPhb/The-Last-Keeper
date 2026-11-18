extends CanvasLayer
## Pause menu, options, the logbook and the dawn / death summary, built in code. It also owns
## the inventory and portable-radio panels (`ui/inventory_panel.gd`, `ui/radio_panel.gd`), which
## keep the night running. Pause, the book and the summary stop the tree.

const INVENTORY_PANEL := preload("res://ui/inventory_panel.gd")
const RADIO_PANEL := preload("res://ui/radio_panel.gd")
const CUTSCENE := preload("res://ui/opening_cutscene.gd")
const STORY_SCENE := preload("res://ui/story_scene.gd")
const SAVE := preload("res://save_game.gd")
const BOOK := preload("res://ui/book_layout.gd")
const BOOK_PAGE := preload("res://ui/book_page.gd")

const FLASH_ENERGY := 7.0
const FLASH_RANGE := 20.0
const LENS_ENERGY := 1.5 ## lens cleaner: stronger beam
const LENS_RANGE := 1.6 ## and longer reach
const FLASH_ANGLE := 30.0
## The beam on PSX surfaces is drawn per pixel by the shaders (global `psx_flashlight`, see
## shaders/psx_common.gdshaderinc): with forced vertex shading the SpotLight3D vanishes between the
## big terrain vertices. The SpotLight3D stays only as a weak fill for StandardMaterial props.
const FLASH_PIXEL_ENERGY := 2.2
const FLASH_FILL := 0.35
const MENU := "res://ui/main_menu.tscn"
const CONTROLS := "Teclado: WASD andar, Shift correr, Espaço pular, E interagir, F lanterna, R rádio, Tab inventário, J livro, Esc pausa.\nControle PS4: analógico esquerdo anda, direito olha, L3 corre, X pula, Quadrado interage, R1 lanterna, direcional para cima rádio, Triângulo inventário, L1 livro, Options pausa."

var _pause: Control
var _pause_box: VBoxContainer
var _settings: SettingsPanel
var _controls: ScrollContainer
var _inventory: Node
var _radio: Node
var _book: Control
var _left: Node ## BOOK_PAGE
var _right: Node ## BOOK_PAGE
var _spread_text: Label
var _spread := 0
var _ending: Control
var _ending_text: Label
var _ending_buttons: VBoxContainer
var _fate: Control
var _fate_title: Label
var _fate_text: Label
var _fate_book: Label
var _fate_buttons: Control
var _fate_tween: Tween
var _flashlight: SpotLight3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	var impact: CanvasLayer = load("res://ui/impact.gd").new()
	impact.name = "Impact"
	get_parent().add_child.call_deferred(impact)
	_pause = _build_pause()
	_inventory = INVENTORY_PANEL.new()
	_inventory.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_inventory)
	_radio = RADIO_PANEL.new()
	_radio.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_radio)
	_book = _build_book()
	_ending = _build_ending()
	_fate = _build_fate()
	GameState.book_requested.connect(open_book)
	GameState.night_ended.connect(_show_ending)
	GameState.player_died.connect(_show_death)
	GameState.flashlight_requested.connect(_toggle_flashlight)
	GameState.scene_requested.connect(_play_scene)
	GameState.radio_requested.connect(open_radio)
	# After every _ready (AudioDirector starts the night): load a save or play the opening.
	_start_session.call_deferred()


## A loaded slot restores the night (a finished one opens its summary); a new game plays the
## opening cutscene and only then starts the clock.
func _start_session() -> void:
	if not GameState.pending_load.is_empty():
		var data: Dictionary = GameState.pending_load
		GameState.pending_load = {}
		SAVE.apply(data, get_parent())
		if GameState.dead:
			_show_death(GameState.death_cause)
		elif GameState.finished:
			_show_ending()
	elif GameState.play_intro:
		GameState.play_intro = false
		var cutscene: Node = CUTSCENE.new()
		get_parent().add_child(cutscene)
		cutscene.finished.connect(_on_opening_finished)


## A story scene from the night (`GameState.SCENE_TRIGGERS`): same player as the opening.
func _play_scene(id: String) -> void:
	var scene: Node = STORY_SCENE.new()
	scene.scene_id = id
	get_parent().add_child(scene)


func _on_opening_finished() -> void:
	GameState.begin_play()
	GameState.autosave()


func _unhandled_input(event: InputEvent) -> void:
	if _ending.visible or _fate.visible:
		return
	var closing := event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")
	if closing:
		if _settings.visible:
			_close_settings()
		elif _book.visible:
			close_book()
		elif _pause.visible:
			resume()
		elif event.is_action_pressed("pause"):
			open_pause()
		else:
			return
	elif _pause.visible:
		return
	elif event.is_action_pressed("inventory") and not _book.visible and not GameState.panel_open and not GameState.dead:
		_inventory.open()
	elif event.is_action_pressed("radio") and not _book.visible and not GameState.panel_open and not GameState.dead:
		open_radio()
	elif event.is_action_pressed("journal") and GameState.book_read:
		if _book.visible:
			close_book()
		else:
			open_book()
	elif event.is_action_pressed("flashlight") and not _book.visible:
		_toggle_flashlight()
	elif _book.visible and event.is_action_pressed("ui_left"):
		_turn(-1)
	elif _book.visible and event.is_action_pressed("ui_right"):
		_turn(1)
	else:
		return
	get_viewport().set_input_as_handled()


func open_pause() -> void:
	_controls.visible = false
	_pause.visible = true
	_set_paused(true)


func resume() -> void:
	_pause.visible = false
	_set_paused(false)


func open_book() -> void:
	GameState.book_read = true
	_book.visible = true
	_turn(0)
	_set_paused(true)


func close_book() -> void:
	_book.visible = false
	_set_paused(false)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused or GameState.panel_open else TouchControls.game_mouse_mode()


func _toggle_flashlight() -> void:
	if not GameState.has_flashlight:
		GameState.say("Você ainda não tem uma lanterna.")
		return
	if _flashlight == null:
		var camera: Camera3D = get_tree().get_first_node_in_group("player").get_node("Head/Camera3D")
		_flashlight = SpotLight3D.new()
		_flashlight.spot_range = FLASH_RANGE
		_flashlight.spot_angle = FLASH_ANGLE
		_flashlight.light_energy = FLASH_ENERGY * FLASH_FILL
		_flashlight.light_color = Color(1, 0.95, 0.8)
		camera.add_child(_flashlight)
		_flashlight.visible = false
	if not _flashlight.visible and GameState.flashlight_battery <= 0.0:
		GameState.say("A lanterna está sem pilha. Procure pilhas na casa, no galpão e no porão.")
		return
	# The beam needs the flashlight in hand: switching it on brings it to the hotbar and selects it.
	if not _flashlight.visible and not GameState.flashlight_ready():
		if not GameState.hold("flashlight"):
			return # it is on the inventory cursor
	_flashlight.visible = not _flashlight.visible
	if not _flashlight.visible:
		_push_beam(0.0, FLASH_RANGE)
	GameState.flashlight_on = _flashlight.visible
	GameState.flashlight_toggled.emit(_flashlight.visible)
	GameState.play("switch")


## Beam strength follows the battery (dims and flickers when low, dies at 0) and the lens boost.
func _process(_delta: float) -> void:
	if _flashlight == null or not _flashlight.visible:
		return
	if GameState.has_flashlight and not GameState.flashlight_ready():
		# another hotbar slot went into the hand: the flashlight goes off with it
		_flashlight.visible = false
		_push_beam(0.0, FLASH_RANGE)
		GameState.flashlight_on = false
		GameState.flashlight_toggled.emit(false)
		GameState.play("switch")
		return
	if GameState.flashlight_battery <= 0.0 or not GameState.has_flashlight:
		_flashlight.visible = false
		_push_beam(0.0, FLASH_RANGE)
		GameState.flashlight_on = false
		GameState.flashlight_toggled.emit(false)
		GameState.play("switch")
		GameState.say("A pilha da lanterna acabou.")
		return
	var charge := GameState.flashlight_battery
	var boost := GameState.lens_left > 0.0
	var power := lerpf(0.3, 1.0, clampf(charge / GameState.FLASH_LOW, 0.0, 1.0))
	if charge < GameState.FLASH_LOW and randf() < 0.08:
		power *= 0.15
	var strength := power * (LENS_ENERGY if boost else 1.0)
	var reach := FLASH_RANGE * (LENS_RANGE if boost else 1.0)
	_flashlight.light_energy = FLASH_ENERGY * FLASH_FILL * strength
	_flashlight.spot_range = reach
	_push_beam(FLASH_PIXEL_ENERGY * strength, reach)


## Feeds the per-pixel beam of the PSX shaders (energy 0 turns it off).
func _push_beam(energy: float, reach: float) -> void:
	var outer := cos(deg_to_rad(FLASH_ANGLE))
	var inner := cos(deg_to_rad(FLASH_ANGLE * 0.6))
	RenderingServer.global_shader_parameter_set(&"psx_flashlight", Vector4(energy, reach, outer, inner))


## Shader globals outlive the scene: never leave the beam on in the menu.
func _exit_tree() -> void:
	_push_beam(0.0, FLASH_RANGE)


func _go_to_menu() -> void:
	GameState.autosave()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


# ---- Portable radio

func open_radio() -> void:
	if GameState.radio_docked:
		GameState.say("O portátil está na base, carregando. Pegue-o no rádio da casa.")
	elif not GameState.has_radio:
		GameState.say("Você não tem um rádio portátil.")
	else:
		_radio.open()


# ---- Pause and options

func _build_pause() -> Control:
	var root := _screen(true)
	_pause_box = root.get_node("Center/Panel/Box")
	_pause_box.add_child(UiKit.heading("PAUSADO"))
	_pause_box.add_child(HSeparator.new())
	_pause_box.add_child(UiKit.button("Continuar", resume))
	_pause_box.add_child(UiKit.button("Opções", _open_settings))
	# The key list is taller than the 240 px screen: it scrolls inside a fixed-height window.
	_controls = ScrollContainer.new()
	_controls.custom_minimum_size = Vector2(236, 78)
	_controls.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_controls.follow_focus = true
	_controls.add_child(UiKit.label(CONTROLS, 224))
	_controls.visible = false
	_pause_box.add_child(UiKit.button("Controles", func() -> void: _controls.visible = not _controls.visible))
	_pause_box.add_child(_controls)
	_pause_box.add_child(UiKit.button("Menu principal", _go_to_menu))
	_pause_box.add_child(UiKit.button("Sair do jogo", func() -> void: get_tree().quit()))
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_close_settings)
	root.add_child(_settings)
	return root


func _open_settings() -> void:
	_pause_box.get_parent().visible = false
	_settings.visible = true


func _close_settings() -> void:
	_settings.visible = false
	_pause_box.get_parent().visible = true


# ---- Logbook

func _build_book() -> Control:
	var root := _screen(true)
	var panel: PanelContainer = root.get_node("Center/Panel")
	panel.add_theme_stylebox_override("panel", UiKit.style(Color(0.13, 0.09, 0.06, 0.98), Color(0.45, 0.32, 0.16)))
	var box: VBoxContainer = panel.get_node("Box")
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 3)
	_left = BOOK_PAGE.new()
	_right = BOOK_PAGE.new()
	pages.add_child(_left)
	pages.add_child(_right)
	box.add_child(pages)
	var bar := HBoxContainer.new()
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(UiKit.button("< Anterior", func() -> void: _turn(-1)))
	_spread_text = UiKit.label("")
	bar.add_child(_spread_text)
	bar.add_child(UiKit.button("Próxima >", func() -> void: _turn(1)))
	bar.add_child(UiKit.button("Fechar", close_book))
	box.add_child(bar)
	return root


func _turn(step: int) -> void:
	var font: Font = _left.get_theme_font("font", "Label")
	var sheets := BOOK.paginate(_entries(), font)
	var spreads := ceili(sheets.size() / 2.0)
	_spread = clampi(_spread + step, 0, spreads - 1)
	var blank := {"title": "", "stamp": "", "body": "", "number": 0}
	_left.show_sheet(sheets[_spread * 2])
	_right.show_sheet(sheets[_spread * 2 + 1] if _spread * 2 + 1 < sheets.size() else blank)
	_spread_text.text = " %d/%d " % [_spread + 1, spreads]
	if step != 0:
		GameState.play("paper")


## The book's contents: {title, body, stamp}; `book_pages.gd` wraps and splits them into sheets.
func _entries() -> Array[Dictionary]:
	var generator := get_tree().get_first_node_in_group("generator")
	var order: String = generator.valve_order_text() if generator else "?"
	var register := func(from: int, to: int) -> String:
		var lines: Array[String] = []
		for ship: Dictionary in GameState.SHIPS.slice(from, to):
			lines.append("%s: %s" % [ship.call, ship.register])
		return "\n".join(lines)
	var note_list: Array[String] = GameState.notes.duplicate()
	if GameState.previous_keeper_line() != "":
		note_list.push_front(GameState.previous_keeper_line())
	var notes := "\n\n".join(note_list) if not note_list.is_empty() else "Nada anotado ainda. Leia placas, etiquetas e inscrições pela ilha."
	var entries: Array[Dictionary] = [
		{"title": "ROTINA DO VIGIA", "stamp": "Das 17:30 às 06:00",
			"body": "Manter a luz acesa, atender o rádio e manter o gerador vivo.\n\nSem energia não há rádio. Sem luz os navios encalham."},
		{"title": "MAPA DA ILHA", "stamp": "Farol 7",
			"body": "Norte: farol, lâmpada no topo.\nLeste: esta casa, rádio e fusíveis.\nOeste: galpão do gerador.\nSul: píer e baú.\nIlhéu a leste: tambor de óleo."},
		{"title": "A LÂMPADA", "stamp": "Queimador de vapor",
			"body": "O óleo só pega com o vaporizador quente e o tanque sob pressão.\nAqueça até o verde, pressão no verde, abra a válvula.\nAbrir frio afoga e trava a válvula.\n\nDê corda no ritmo da catraca. Limpe a lente."},
		{"title": "ONDE PEGAR ÓLEO", "stamp": "Reservas",
			"body": "O tambor está no ilhéu a leste, depois da praia. Só se cruza pelas pedras na maré baixa. Há 3 latas.\n\nNa casa, o porão tem reservas e a despensa (cadeado de 3 números).\n\nÁgua: cisterna junto do rádio."},
		{"title": "GERADOR E ENERGIA", "stamp": "Galpão do gerador",
			"body": "Abrir as válvulas na ordem: %s.\nCombustível: barris atrás do galpão. O tanque enche com uma lata.\n\nFusíveis: o gerador aguenta só dois circuitos por vez." % order},
		{"title": "RÁDIO E CHAMADOS", "stamp": "Mesa do rádio",
			"body": "Com o rádio ligado, chega uma chamada. Gire a sintonia até o sinal ficar claro, ouça a carga e compare com o registro. Igual: autorize. Diferente: recuse.\n\nSem luz no farol, o navio encalha."},
		{"title": "REGISTRO DE CARGAS", "stamp": "Navios 1 a 3", "body": register.call(0, 3)},
		{"title": "REGISTRO DE CARGAS", "stamp": "Navios 4 a 6",
			"body": register.call(3, 6) + "\n\nCarga diferente da registrada: não autorize."},
		{"title": "ANOTAÇÕES", "stamp": "Noite %d · até as %s" % [GameState.night, GameState.clock_text()], "body": notes},
	]
	if GameState.scenes_seen.get("portinho_friend", false):
		entries.append({"title": "O BONEQUINHO", "stamp": "Mesa do rádio",
			"body": "Achei no fundo do armário do rádio um bonequinho de lata, um farol com chapéu azul, polegar levantado. Não sei de quem era. Anselmo? Algum filho de vigia? Tem ferrugem só nas juntas, como se alguém o tivesse segurado por décadas. Pus na mesa, junto ao rádio. Não pedi companhia, mas o polegar parece saber de algo que eu não sei."})
	return entries


# ---- Dawn summary

func _build_ending() -> Control:
	var root := _screen(true)
	var box: VBoxContainer = root.get_node("Center/Panel/Box")
	box.add_child(UiKit.heading("AMANHECER"))
	box.add_child(HSeparator.new())
	_ending_text = UiKit.label("", 180)
	box.add_child(_ending_text)
	_ending_buttons = box
	box.add_child(UiKit.button("Continuar", _continue_night))
	box.add_child(UiKit.button("Menu principal", _end_to_menu))
	return root


## "Continuar" at dawn: the boatman's scene, then the next night on a rebuilt island.
func _continue_night() -> void:
	_ending.visible = false
	_set_paused(false)
	var scene: Node = STORY_SCENE.new()
	scene.scene_id = "dawn"
	get_parent().add_child(scene)
	scene.finished.connect(_start_next_night)


## Next night: GameState moves on, the slot gets the new night's start and the scene reloads from it.
func _start_next_night() -> void:
	var data := _advance_and_save()
	get_tree().paused = false
	GameState.pending_load = data
	GameState.play_intro = false
	get_tree().reload_current_scene()


## "Menu principal" at dawn: the progress is saved as the next night, so the menu's Continuar resumes it.
func _end_to_menu() -> void:
	_advance_and_save()
	GameState.in_game = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU)


func _advance_and_save() -> Dictionary:
	GameState.advance_night()
	var data := GameState.night_start_data()
	if GameState.save_slot > 0:
		SAVE.store(GameState.save_slot, data)
	return data


## Death and failed-lighthouse screen: no brass frame, black with a vignette, text typed slowly.
func _build_fate() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.visible = false
	var back := ColorRect.new()
	back.name = "Back"
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	back.color = Color(0.05, 0.0, 0.0)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(back)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0, 0, 0, 0))
	gradient.set_color(1, Color(0, 0, 0, 1))
	gradient.set_offset(0, 0.35)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 48
	var vignette := TextureRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.texture = texture
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	center.add_child(box)
	_fate_title = UiKit.label("", 260, UiKit.BLOOD)
	_fate_title.add_theme_font_size_override("font_size", UiKit.HEADING_SIZE)
	_fate_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_fate_title)
	_fate_text = UiKit.label("", 260, Color(0.82, 0.76, 0.66))
	_fate_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_fate_text)
	_fate_book = UiKit.label("", 260, Color(0.68, 0.62, 0.52))
	_fate_book.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_fate_book)
	_fate_buttons = VBoxContainer.new()
	_fate_buttons.add_child(UiKit.button("Tentar de novo", _retry))
	_fate_buttons.add_child(UiKit.button("Menu principal", _go_to_menu))
	box.add_child(_fate_buttons)
	add_child(root)
	return root


## Starts the night again from the last save of the slot (autosave), or from 17:30 without one.
func _retry() -> void:
	get_tree().paused = false
	GameState.play_intro = false
	if GameState.save_slot > 0 and SAVE.exists(GameState.save_slot):
		GameState.pending_load = SAVE.read(GameState.save_slot)
	get_tree().reload_current_scene()


func _show_death(cause: String) -> void:
	var fate: Dictionary = GameState.fate(cause)
	var tone := Color(0.05, 0.0, 0.0)
	_show_fate(fate, "%s. %s." % [GameState.clock_text(), cause.to_upper() if cause != "" else "SEM CAUSA"], tone, UiKit.BLOOD, true)


func _show_fate(fate: Dictionary, header: String, tone: Color, title_color: Color, died: bool) -> void:
	_pause.visible = false
	_book.visible = false
	for panel: Node in [_inventory, _radio]:
		panel.close()
	_fate.get_node("Back").color = tone
	_fate_title.text = fate["title"]
	_fate_title.add_theme_color_override("font_color", title_color)
	_fate_text.text = "%s\n\n%s\nNavios salvos: %d. Perdidos: %d." % [header, fate["text"], GameState.ships_saved, GameState.ships_lost]
	if GameState.invasion_summary() != "":
		_fate_text.text += "\n" + GameState.invasion_summary()
	var who := "Vigia %d" % (GameState.keeper_number() - 1 if died else GameState.keeper_number())
	_fate_book.text = "Livro de registros, %s:\n«%s»" % [who, fate["book"]]
	_fate_title.visible_ratio = 0.0
	_fate_text.visible_ratio = 0.0
	_fate_book.visible_ratio = 0.0
	_fate_buttons.visible = false
	_fate.modulate.a = 0.0
	_fate.visible = true
	_set_paused(true)
	if _fate_tween:
		_fate_tween.kill()
	_fate_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fate_tween.tween_property(_fate, "modulate:a", 1.0, 2.0).set_delay(0.8)
	_fate_tween.tween_property(_fate_title, "visible_ratio", 1.0, 0.07 * fate["title"].length())
	_fate_tween.tween_interval(0.6)
	_fate_tween.tween_property(_fate_text, "visible_ratio", 1.0, 0.045 * _fate_text.text.length())
	_fate_tween.tween_interval(0.8)
	_fate_tween.tween_property(_fate_book, "visible_ratio", 1.0, 0.04 * _fate_book.text.length())
	_fate_tween.tween_callback(func() -> void:
		_fate_buttons.visible = true
		(_fate_buttons.get_child(0) as Button).grab_focus())
	if died:
		get_tree().create_timer(1.6, true).timeout.connect(func() -> void: GameState.play("heart"))
		get_tree().create_timer(2.5, true).timeout.connect(func() -> void: GameState.play("heart"))


func _show_ending() -> void:
	if GameState.lighthouse_failed():
		_show_fate(GameState.FAILURE, "06:00. O FAROL FALHOU", Color(0.02, 0.04, 0.05), Color(0.55, 0.62, 0.62), false)
		GameState.play("bell")
		return
	_pause.visible = false
	_book.visible = false
	for panel: Node in [_inventory, _radio]:
		panel.close()
	var verdict := "O farol resistiu." if GameState.ships_lost <= GameState.ships_saved else "Muitos não voltaram."
	_ending_text.text = "06:00. AMANHECEU (noite %d)\n\nNavios salvos: %d\nNavios perdidos: %d\n%s\n%s" % [GameState.night, GameState.ships_saved, GameState.ships_lost, GameState.invasion_summary(), verdict]
	_ending.visible = true
	(_ending_buttons.get_child(_ending_buttons.get_child_count() - 2) as Button).grab_focus.call_deferred()
	GameState.play("bell")
	_set_paused(true)


# ---- Widgets

func _screen(blocks_mouse: bool) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP if blocks_mouse else Control.MOUSE_FILTER_IGNORE
	root.visible = false
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55 if blocks_mouse else 0.3)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	var panel := UiKit.panel()
	panel.name = "Panel"
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	add_child(root)
	return root
