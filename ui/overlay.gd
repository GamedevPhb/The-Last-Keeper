extends CanvasLayer
## Pause menu, inventory and the logbook, built in code so they share one look.
## Pause and the book stop the tree; the inventory is a glance that keeps the night running.

const FONT_SIZE := 8
const CONTROLS := "WASD andar   Shift correr   E interagir (segure para ações longas)\nF lanterna   Tab inventário   J livro   Esc pausa"

var _pause: Control
var _controls: Label
var _inventory: Control
var _inventory_text: Label
var _book: Control
var _left: Label
var _right: Label
var _spread_text: Label
var _spread := 0
var _flashlight: SpotLight3D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_pause = _build_pause()
	_inventory = _build_inventory()
	_book = _build_book()
	GameState.book_requested.connect(open_book)
	GameState.changed.connect(_refresh_inventory)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _book.visible:
			close_book()
		elif _pause.visible:
			resume()
		elif _inventory.visible:
			_inventory.visible = false
		else:
			open_pause()
	elif _pause.visible:
		return
	elif event.is_action_pressed("inventory") and not _book.visible:
		_inventory.visible = not _inventory.visible
		_refresh_inventory()
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
	_inventory.visible = false
	_controls.visible = false
	_pause.visible = true
	_set_paused(true)


func resume() -> void:
	_pause.visible = false
	_set_paused(false)


func open_book() -> void:
	GameState.book_read = true
	_inventory.visible = false
	_book.visible = true
	_turn(0)
	_set_paused(true)


func close_book() -> void:
	_book.visible = false
	_set_paused(false)


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED


func _toggle_flashlight() -> void:
	if not GameState.has_flashlight:
		GameState.say("Você ainda não tem uma lanterna.")
		return
	if _flashlight == null:
		var camera: Camera3D = get_tree().get_first_node_in_group("player").get_node("Head/Camera3D")
		_flashlight = SpotLight3D.new()
		_flashlight.spot_range = 16.0
		_flashlight.spot_angle = 26.0
		_flashlight.light_energy = 3.0
		_flashlight.light_color = Color(1, 0.95, 0.8)
		camera.add_child(_flashlight)
		_flashlight.visible = false
	_flashlight.visible = not _flashlight.visible


# ---- Inventory

func _refresh_inventory() -> void:
	if not _inventory.visible:
		return
	_inventory_text.text = "INVENTÁRIO\n\nLata de óleo: %d\nLata de combustível: %d\nLanterna: %s\nLivro de registros: %s\n\nOBJETIVO\n%s" % [
		GameState.oil_cans, GameState.fuel_cans, "sim" if GameState.has_flashlight else "não",
		"na mesa da casa" if not GameState.book_read else "lido (J abre)", GameState.objective()]


func _build_inventory() -> Control:
	var root := _screen(false)
	_inventory_text = _label("", 160)
	root.get_node("Center/Panel/Box").add_child(_inventory_text)
	return root


# ---- Pause

func _build_pause() -> Control:
	var root := _screen(true)
	var box: VBoxContainer = root.get_node("Center/Panel/Box")
	box.add_child(_label("PAUSADO", 0))
	box.add_child(_button("Continuar", resume))
	_controls = _label(CONTROLS, 220)
	_controls.visible = false
	box.add_child(_button("Controles", func() -> void: _controls.visible = not _controls.visible))
	box.add_child(_controls)
	box.add_child(_button("Sair do jogo", func() -> void: get_tree().quit()))
	return root


# ---- Logbook

func _build_book() -> Control:
	var root := _screen(true)
	var panel: PanelContainer = root.get_node("Center/Panel")
	panel.add_theme_stylebox_override("panel", _style(Color(0.2, 0.14, 0.09, 0.97), Color(0.08, 0.05, 0.03)))
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
	bar.add_child(_button("< Anterior", func() -> void: _turn(-1)))
	_spread_text = _label("", 0)
	bar.add_child(_spread_text)
	bar.add_child(_button("Próxima >", func() -> void: _turn(1)))
	bar.add_child(_button("Fechar", close_book))
	box.add_child(bar)
	return root


func _turn(step: int) -> void:
	var pages := _pages()
	var spreads := ceili(pages.size() / 2.0)
	_spread = clampi(_spread + step, 0, spreads - 1)
	_left.text = pages[_spread * 2]
	_right.text = pages[_spread * 2 + 1] if _spread * 2 + 1 < pages.size() else ""
	_spread_text.text = " %d/%d " % [_spread + 1, spreads]


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
		"ROTINA DO VIGIA\n\nManter a luz acesa a noite toda, atender o rádio e manter o gerador vivo.\n\nSem energia não há rádio. Sem luz não há navios.",
		"MAPA DA ILHA\n\nNorte: farol, lâmpada no topo.\nLeste: esta casa, rádio e fusíveis.\nOeste: galpão do gerador.\nSul: píer e baú.\nIlhéu a leste: tambor de óleo, só a pé na maré baixa.",
		"REGISTRO DE CARGAS\n\n" + register.call(0, 3),
		"REGISTRO DE CARGAS\n\n" + register.call(3, 6) + "\n\nCarga diferente da registrada: não autorize.",
		"MANUAL DO GERADOR\n\nAbrir as válvulas na ordem:\n%s\n\nO tanque precisa de combustível. O gerador aguenta dois circuitos por vez." % order,
		"ANOTAÇÕES\n\n" + notes,
	]


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
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.add_theme_stylebox_override("panel", _style(Color(0.05, 0.06, 0.08, 0.94), Color(0.45, 0.38, 0.26)))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	add_child(root)
	return root


func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	return style


func _label(text: String, width: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.92, 0.9, 0.82))
	if width > 0:
		label.custom_minimum_size.x = width
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _page_label() -> Label:
	var label := _label("", 120)
	label.custom_minimum_size.y = 120
	label.add_theme_color_override("font_color", Color(0.14, 0.09, 0.04))
	var style := _style(Color(0.76, 0.7, 0.55), Color(0.4, 0.32, 0.2))
	label.add_theme_stylebox_override("normal", style)
	return label


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.pressed.connect(action)
	return button
