class_name PuzzleConsole
extends CanvasLayer
## Shared base for the brass puzzle panels (lamp, breakers), built in code.
## A panel does not pause the night: it only locks the keeper's walking and looking, and
## flags `GameState.panel_open` so the HUD steps aside. Messages from `GameState.say()`
## show inside the panel instead.
## Input: click an icon (hold for continuous actions); keys 1-N; A/D or arrows move the
## focus and E/Space use it; Q or Esc closes. Pad: d-pad/left stick + X or Square, Circle
## closes, Options closes and lets the overlay pause.
## Touch (`TouchControls.enabled`): an X closes, the key help hides, icons are tapped or held.
## Subclasses fill `_build_body()`, `_action_count()`, `_on_press()` and `_refresh()`;
## hold actions call `_begin_hold()` and get `_hold_tick()` every frame while held.

const LAYER := 12 ## above the HUD (10), below the pause overlay (20)
const TOAST_TIME := 4.0

## Shared 16x16 pixel-art palette for `icon()`.
const PALETTE := {
	"k": Color(0.03, 0.05, 0.05),
	"b": Color(0.78, 0.64, 0.34),
	"l": Color(0.87, 0.78, 0.6),
	"d": Color(0.36, 0.2, 0.11),
	"a": Color(1.0, 0.62, 0.1),
	"B": Color(0.2, 0.4, 1.0),
	"c": Color(0.55, 0.85, 1.0),
	"w": Color(0.88, 0.84, 0.7),
	"g": Color(0.5, 0.52, 0.48),
	"s": Color(0.62, 0.78, 0.68),
	"r": Color(0.72, 0.12, 0.09),
	"y": Color(1.0, 0.9, 0.45),
}

var _player: Player
var _focus := 0
var _held := -1
var _hold_check := Callable()
var _toast_left := 0.0
var _title: Label
var _header: Label
var _body: VBoxContainer
var _message: Label
var _buttons: Array[Button] = []
var _dim: ColorRect
var _help: Label
var _panel: PanelContainer
var _top: HBoxContainer
## Buttons shown only with touch controls (the X, the inventory's USAR / LARGAR).
var _touch_only: Array[Control] = []
var _normal_box: StyleBox
var _focus_box: StyleBox


func _ready() -> void:
	layer = LAYER
	# The baked project theme (ui/theme.tres); building UiKit's theme here would leak its cache.
	var theme := ThemeDB.get_project_theme()
	if theme == null:
		theme = ThemeDB.get_default_theme()
	_normal_box = theme.get_stylebox("normal", "Button")
	_focus_box = theme.get_stylebox("focus", "Button")
	_build_frame()
	GameState.toast.connect(_on_toast)
	visible = false


func is_open() -> bool:
	return visible


func open(by: Player = null) -> void:
	_player = by if by else get_tree().get_first_node_in_group("player") as Player
	if _player:
		_player.locked = true
	_release()
	_toast_left = 0.0
	_message.text = ""
	_focus = clampi(_initial_focus(), 0, _action_count() - 1)
	for button in _touch_only:
		button.visible = TouchControls.enabled
	_help.visible = not TouchControls.enabled
	visible = true
	GameState.set_panel_open(self, true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh()
	_style_buttons()


func close() -> void:
	if not visible:
		return
	_release()
	visible = false
	GameState.set_panel_open(self, false)
	if _player:
		_player.locked = false
	Input.mouse_mode = TouchControls.game_mouse_mode()


func _exit_tree() -> void:
	if visible:
		GameState.set_panel_open(self, false)


## Runs the action at `index` as if its icon were pressed. `still_held` reports whether the
## button/key that started it is still down, for hold actions.
func press(index: int, still_held := Callable()) -> void:
	_focus = index
	_release()
	_on_press(index, still_held)


# ---- Overridables

func _build_body(_box: VBoxContainer) -> void:
	pass


func _action_count() -> int:
	return _buttons.size()


func _initial_focus() -> int:
	return 0


func _on_press(_index: int, _still_held: Callable) -> void:
	pass


func _hold_tick(_delta: float) -> void:
	pass


func _refresh() -> void:
	pass


func _help_text() -> String:
	return "[1-%d] ações  [A/D] foco  [E/Espaço] usar  [Q/Esc] fechar" % _action_count()


# ---- Holds

func _begin_hold(index: int, still_held: Callable) -> void:
	_held = index
	_hold_check = still_held


func _release() -> void:
	_held = -1
	_hold_check = Callable()


func _process(delta: float) -> void:
	if not visible:
		return
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			_message.text = ""
	if _held >= 0:
		if _hold_check.is_valid() and not _hold_check.call():
			_release()
		else:
			_hold_tick(delta)
	_refresh()
	_style_buttons()


func _on_toast(text: String) -> void:
	if not visible:
		return
	_message.text = text
	_toast_left = TOAST_TIME


# ---- Input

func _input(event: InputEvent) -> void:
	if not visible or event is InputEventMouse:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		var code := key.physical_keycode
		if code >= KEY_1 and code < KEY_1 + _action_count():
			press(code - KEY_1, func() -> bool: return Input.is_physical_key_pressed(code))
			get_viewport().set_input_as_handled()
			return
		if code == KEY_Q or code == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause"):
		# Options on the pad: close here and let the overlay open the pause menu.
		close()
		return
	if event.is_action_pressed("ui_cancel"):
		close()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_move_focus(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_move_focus(1)
	else:
		var trigger := ""
		for action_name in ["interact", "jump", "ui_accept"]:
			if event.is_action_pressed(action_name):
				trigger = action_name
				break
		if trigger.is_empty():
			return
		press(_focus, func() -> bool: return Input.is_action_pressed(trigger))
	get_viewport().set_input_as_handled()


func _move_focus(step: int) -> void:
	_release()
	_focus = posmod(_focus + step, _action_count())


# ---- Layout helpers

func _build_frame() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0.3)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_panel = UiKit.panel()
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_panel.add_child(box)

	var top := HBoxContainer.new()
	_top = top
	_title = UiKit.label("", 0, UiKit.BRASS)
	top.add_child(_title)
	_header = UiKit.label("")
	_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(_header)
	box.add_child(top)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 3)
	box.add_child(_body)
	_build_body(_body)
	_top.add_child(_touch_button("X", close))

	_message = UiKit.label("", 270, UiKit.BONE)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size.y = 11
	box.add_child(_message)
	_help = UiKit.label(_help_text(), 0, Color(0.7, 0.75, 0.7, 0.7))
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_help)


## A 40x40 icon button wired to `press(index)`; holding the mouse keeps hold actions going.
func _icon_button(index: int, texture: Texture2D, tooltip: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(40, 40)
	button.focus_mode = Control.FOCUS_NONE
	button.icon = texture
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_constant_override("icon_max_width", 32)
	button.tooltip_text = tooltip
	button.button_down.connect(func() -> void: press(index, func() -> bool: return button.button_pressed))
	button.mouse_entered.connect(_hover.bind(index))
	_buttons.append(button)
	return button


## A 24 px button (about 9 mm on a phone) that only shows with touch controls.
func _touch_button(text: String, action: Callable) -> Button:
	var button := UiKit.button(text, action)
	button.custom_minimum_size = Vector2(24, 24)
	button.focus_mode = Control.FOCUS_NONE
	button.visible = false
	_touch_only.append(button)
	return button


func _hover(index: int) -> void:
	if _held < 0:
		_focus = index


func _style_buttons() -> void:
	for i in _buttons.size():
		_buttons[i].add_theme_stylebox_override("normal", _focus_box if i == _focus else _normal_box)


## A plaque with engraved brass text, for the one-line tutorial at the foot of a panel.
static func plaque(text: String) -> Label:
	var plate := UiKit.label(text, 0, UiKit.BRASS)
	plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART # wraps instead of widening the panel past the viewport
	var plate_box := UiKit.style(Color(0.16, 0.1, 0.05), UiKit.RUST)
	plate_box.set_content_margin_all(2)
	plate.add_theme_stylebox_override("normal", plate_box)
	return plate


## Square pixel art (16x16 by default) from rows of PALETTE characters ('.' or unknown = transparent).
static func icon(rows: Array, side := 16) -> ImageTexture:
	var img := Image.create(side, side, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in mini(rows.size(), side):
		var row: String = rows[y]
		for x in mini(row.length(), side):
			if PALETTE.has(row[x]):
				img.set_pixel(x, y, PALETTE[row[x]])
	return ImageTexture.create_from_image(img)
