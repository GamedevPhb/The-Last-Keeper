extends CanvasLayer
## Pause menu, options, the logbook and the dawn / death summary, built in code. It also owns
## the inventory and portable-radio panels (`ui/inventory_panel.gd`, `ui/radio_panel.gd`), which
## keep the night running. Pause, the book and the summary stop the tree.

const INVENTORY_PANEL := preload("res://ui/inventory_panel.gd")
const RADIO_PANEL := preload("res://ui/radio_panel.gd")
const CUTSCENE := preload("res://ui/opening_cutscene.gd")
const SAVE := preload("res://save_game.gd")

const MENU := "res://ui/main_menu.tscn"
const CONTROLS := "Teclado: WASD andar, Shift correr, Espaço pular, E interagir, F lanterna, R rádio, Tab inventário, J livro, Esc pausa.\nControle PS4: analógico esquerdo anda, direito olha, L3 corre, X pula, Quadrado interage, R1 lanterna, direcional para cima rádio, Triângulo inventário, L1 livro, Options pausa."

var _pause: Control
var _pause_box: VBoxContainer
var _settings: SettingsPanel
var _controls: Label
var _inventory: Node
var _radio: Node
var _book: Control
var _left: Label
var _right: Label
var _spread_text: Label
var _spread := 0
var _ending: Control
var _ending_text: Label
var _flashlight: SpotLight3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_pause = _build_pause()
	_inventory = INVENTORY_PANEL.new()
	_inventory.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_inventory)
	_radio = RADIO_PANEL.new()
	_radio.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_radio)
	_book = _build_book()
	_ending = _build_ending()
	GameState.book_requested.connect(open_book)
	GameState.night_ended.connect(_show_ending)
	GameState.player_died.connect(_show_death)
	GameState.flashlight_requested.connect(_toggle_flashlight)
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


func _on_opening_finished() -> void:
	GameState.begin_play()
	GameState.autosave()


func _unhandled_input(event: InputEvent) -> void:
	if _ending.visible:
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused or GameState.panel_open else Input.MOUSE_MODE_CAPTURED


func _toggle_flashlight() -> void:
	if not GameState.has_flashlight:
		GameState.say("Você ainda não tem uma lanterna.")
		return
	if _flashlight == null:
		var camera: Camera3D = get_tree().get_first_node_in_group("player").get_node("Head/Camera3D")
		_flashlight = SpotLight3D.new()
		_flashlight.spot_range = 20.0
		_flashlight.spot_angle = 30.0
		_flashlight.light_energy = 7.0
		_flashlight.light_color = Color(1, 0.95, 0.8)
		camera.add_child(_flashlight)
		_flashlight.visible = false
	_flashlight.visible = not _flashlight.visible
	GameState.play("switch")


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
	_controls = UiKit.label(CONTROLS, 230)
	_controls.visible = false
	_pause_box.add_child(UiKit.button("Controles", func() -> void: _controls.visible = not _controls.visible))
	_pause_box.add_child(_controls)
	_pause_box.add_child(UiKit.button("Menu principal", _go_to_menu))
	_pause_box.add_child(UiKit.button("Sair do jogo", func() -> void: get_tree().quit()))
	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(_close_settings)
	root.get_node("Center").add_child(_settings)
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
	_left = _page_label()
	_right = _page_label()
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
	var pages := _pages()
	var spreads := ceili(pages.size() / 2.0)
	_spread = clampi(_spread + step, 0, spreads - 1)
	_left.text = pages[_spread * 2]
	_right.text = pages[_spread * 2 + 1] if _spread * 2 + 1 < pages.size() else ""
	_spread_text.text = " %d/%d " % [_spread + 1, spreads]
	if step != 0:
		GameState.play("paper")


func _pages() -> Array[String]:
	var generator := get_tree().get_first_node_in_group("generator")
	var order: String = generator.valve_order_text() if generator else "?"
	var register := func(from: int, to: int) -> String:
		var lines: Array[String] = []
		for ship: Dictionary in GameState.SHIPS.slice(from, to):
			lines.append("%s: %s" % [ship.call, ship.register])
		return "\n".join(lines)
	var notes := "\n\n".join(GameState.notes) if not GameState.notes.is_empty() else "Nada anotado ainda. Leia placas, etiquetas e inscrições pela ilha."
	return [
		"ROTINA DO VIGIA\n\nDas 17:30 às 06:00: manter a luz acesa, atender o rádio e manter o gerador vivo.\n\nSem energia não há rádio. Sem luz os navios encalham.",
		"MAPA DA ILHA\n\nNorte: farol, lâmpada no topo.\nLeste: esta casa, rádio e fusíveis.\nOeste: galpão do gerador.\nSul: píer e baú.\nIlhéu a leste: tambor de óleo.",
		"A LÂMPADA\n\nQueimador de vapor: o óleo só pega com o vaporizador quente e o tanque sob pressão.\nAqueça até o verde, pressão no verde, abra a válvula.\nAbrir frio afoga e trava a válvula.\n\nDê corda no ritmo da catraca. Limpe a lente.",
		"ONDE PEGAR ÓLEO\n\nO tambor está no ilhéu a leste, depois da praia. Só se cruza pelas pedras na maré baixa. Há 3 latas.\n\nNa casa, o porão tem reservas e a despensa (cadeado de 3 números).\n\nÁgua: cisterna junto do rádio.",
		"GERADOR E ENERGIA\n\nAbrir as válvulas na ordem: %s.\nCombustível: barris atrás do galpão. O tanque enche com uma lata.\n\nFusíveis: o gerador aguenta só dois circuitos por vez." % order,
		"RÁDIO E CHAMADOS\n\nCom o rádio ligado, chega uma chamada. Gire a sintonia até o sinal ficar claro, ouça a carga e compare com o registro. Igual: autorize. Diferente: recuse.\n\nSem luz no farol, o navio encalha.",
		"REGISTRO DE CARGAS\n\n" + register.call(0, 3),
		"REGISTRO DE CARGAS\n\n" + register.call(3, 6) + "\n\nCarga diferente da registrada: não autorize.",
		"ANOTAÇÕES\n\n" + notes,
	]


# ---- Dawn summary

func _build_ending() -> Control:
	var root := _screen(true)
	var box: VBoxContainer = root.get_node("Center/Panel/Box")
	box.add_child(UiKit.heading("AMANHECER"))
	box.add_child(HSeparator.new())
	_ending_text = UiKit.label("", 180)
	box.add_child(_ending_text)
	box.add_child(UiKit.button("Recomeçar a noite", _restart))
	box.add_child(UiKit.button("Menu principal", _go_to_menu))
	return root


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _show_death(cause: String) -> void:
	_pause.visible = false
	_book.visible = false
	for panel: Node in [_inventory, _radio]:
		panel.close()
	_ending_text.text = "%s. %s\n\n%s levou o vigia.\n\nNavios salvos: %d\nNavios perdidos: %d" % [
		GameState.clock_text(), "O FAROL FICOU SEM VIGIA", cause, GameState.ships_saved, GameState.ships_lost]
	_ending.visible = true
	_ending.modulate.a = 0.0
	create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(_ending, "modulate:a", 1.0, 2.5)
	_set_paused(true)


func _show_ending() -> void:
	_pause.visible = false
	_book.visible = false
	for panel: Node in [_inventory, _radio]:
		panel.close()
	var verdict := "O farol resistiu." if GameState.ships_lost <= GameState.ships_saved else "Muitos não voltaram."
	_ending_text.text = "06:00. AMANHECEU\n\nNavios salvos: %d\nNavios perdidos: %d\n\n%s" % [GameState.ships_saved, GameState.ships_lost, verdict]
	_ending.visible = true
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


func _page_label() -> Label:
	var item := UiKit.label("", 120, Color(0.14, 0.09, 0.04))
	item.custom_minimum_size.y = 125
	item.add_theme_stylebox_override("normal", UiKit.style(Color(0.76, 0.7, 0.55), Color(0.4, 0.32, 0.2)))
	return item
