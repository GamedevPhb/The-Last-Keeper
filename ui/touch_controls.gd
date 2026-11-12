class_name TouchControls
extends CanvasLayer
## Touch HUD for phones (and for testing on PC with the option forced on): a floating stick on
## the left half walks (pushed to the rim it sprints), dragging on the right half looks, and
## round brass buttons fire the existing input actions (`InputEventAction`), so the Player,
## overlay and consoles run the same code as with keys or a pad. Multitouch: every finger is
## tracked by its index. Hidden while a panel is open, the tree is paused or the keeper died.
## Without a touchscreen, the left mouse button stands in for finger 0.
## `enabled` (static) also drives the touch tweaks elsewhere: bigger themed buttons, close
## buttons on the consoles, tap / hold in the inventory, hold-to-skip in the cutscene.

enum { AUTO, ON, OFF }

const LAYER := 11 ## above the HUD (10), below the consoles (12)
const STICK_RADIUS := 30.0
const KNOB_RADIUS := 11.0
const DEAD_ZONE := 0.12
const SPRINT_AT := 0.92 ## stick pushed to the rim
const SLOP := 4.0 ## extra pixels around a button that still count as a hit
const TOUCH_PAD := 4.0 ## extra top/bottom margin on themed buttons: ~25 px tall at 320x240
const AXES := ["move_left", "move_right", "move_forward", "move_back", "sprint"]

## Buttons, placed from the bottom-right corner (`at`) so they ride the right edge in any width.
const BUTTONS := [
	{"action": "pause", "icon": "pause", "at": Vector2(-16, -208), "radius": 12.0},
	{"action": "inventory", "icon": "bag", "at": Vector2(-16, -180), "radius": 12.0},
	{"action": "radio", "icon": "radio", "at": Vector2(-16, -152), "radius": 12.0},
	{"action": "journal", "icon": "book", "at": Vector2(-16, -124), "radius": 12.0},
	{"action": "flashlight", "icon": "flashlight", "at": Vector2(-16, -96), "radius": 12.0},
	{"action": "interact", "icon": "hand", "at": Vector2(-50, -44), "radius": 18.0},
	{"action": "jump", "icon": "jump", "at": Vector2(-20, -20), "radius": 14.0},
]

const ICONS := {
	"hand": [
		"",
		"......kk",
		".....kwwk",
		".....kwwk",
		".....kwwkkk",
		".....kwwkwwkk",
		"..kk.kwwkwwkwk",
		".kwwkkwwwwwkwk",
		".kwwwkwwwwwwwk",
		"..kwwwwwwwwwwk",
		"...kwwwwwwwwk",
		"....kwwwwwwwk",
		".....kwwwwwk",
		".....kkkkkk",
	],
	"jump": [
		"",
		"",
		".......ww",
		"......wwww",
		".....wwwwww",
		"....wwwwwwww",
		"...wwwwwwwwww",
		"......wwww",
		"......wwww",
		"......wwww",
		"......wwww",
		"......wwww",
		"......wwww",
	],
	"pause": [
		"",
		"",
		"",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
		".....ww..ww",
	],
	"bag": [
		"",
		"",
		"..www.www.www",
		"..wbw.wbw.wbw",
		"..www.www.www",
		"",
		"..www.www.www",
		"..wbw.wbw.wbw",
		"..www.www.www",
		"",
		"..www.www.www",
		"..wbw.wbw.wbw",
		"..www.www.www",
	],
	"book": [
		"",
		"",
		"",
		".kkkkkk.kkkkkk",
		".kwwwwwkwwwwwk",
		".kwddwwkwddwwk",
		".kwwwwwkwwwwwk",
		".kwddwwkwddwwk",
		".kwwwwwkwwwwwk",
		".kwddwwkwddwwk",
		".kwwwwwkwwwwwk",
		".kkkkkkbkkkkkk",
		"......kbk",
	],
}

static var enabled := false
static var _margins := {}

@export var player: Player

var _canvas: Control
var _size := Vector2(320, 240)
var _shown := false
var _stick_touch := -1
var _stick_center := Vector2.ZERO
var _stick := Vector2.ZERO
var _look_touch := -1
## Per button: {action, icon (Texture2D), at, radius, touch}.
var _buttons: Array[Dictionary] = []
var _held_axes := {}
var _hold := 0.0
var _focused := false
var _mouse_down := false


## Re-reads the option (auto / on / off) and the device; returns whether touch is on.
## Called by Settings.apply(), so it runs at boot and on every option change.
static func update() -> bool:
	var settings := _settings()
	var mode: int = int(settings.values.get("touch", AUTO)) if settings else AUTO
	var now := mode == ON or (mode == AUTO and (OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()))
	if now != enabled:
		enabled = now
		_apply_theme(now)
	return enabled


## The mouse mode for walking around: captured with a mouse, free with touch.
static func game_mouse_mode() -> Input.MouseMode:
	return Input.MOUSE_MODE_VISIBLE if enabled else Input.MOUSE_MODE_CAPTURED


static func _settings() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("Settings") if tree else null


## Taller themed buttons and checkboxes with touch (~9 mm on a phone). Edits the project theme
## in memory only; ui/theme.tres on disk keeps the PC sizes.
static func _apply_theme(on: bool) -> void:
	var theme := ThemeDB.get_project_theme()
	if theme == null:
		return
	for kind in ["Button", "CheckBox"]:
		for state in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			if not theme.has_stylebox(state, kind):
				continue
			var box := theme.get_stylebox(state, kind)
			var id := box.get_instance_id()
			if not _margins.has(id):
				_margins[id] = Vector2(box.content_margin_top, box.content_margin_bottom)
			var base: Vector2 = _margins[id]
			box.content_margin_top = base.x + (TOUCH_PAD if on else 0.0)
			box.content_margin_bottom = base.y + (TOUCH_PAD if on else 0.0)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.root.propagate_notification(Control.NOTIFICATION_THEME_CHANGED)


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("touch_controls")
	_canvas = Canvas.new()
	_canvas.hud = self
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.modulate.a = 0.75
	add_child(_canvas)
	for spec: Dictionary in BUTTONS:
		var button := spec.duplicate()
		button.icon = _icon(spec.icon)
		button.touch = -1
		_buttons.append(button)
	if player:
		player.hold_progress_changed.connect(func(ratio: float) -> void: _hold = ratio)
		player.focus_changed.connect(func(target: Interactable) -> void: _focused = target != null)
	visible = false


func _icon(key: String) -> Texture2D:
	match key:
		"flashlight", "radio":
			return InventoryPanel.item_texture(key)
	return PuzzleConsole.icon(ICONS[key])


func _process(_delta: float) -> void:
	_size = get_viewport().get_visible_rect().size
	var show := enabled and not GameState.panel_open and not GameState.dead and not get_tree().paused
	if show != _shown:
		_shown = show
		visible = show
		if not show:
			release_all()
	if enabled and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _shown:
		_canvas.queue_redraw()


## Lets go of every finger: stick, look and buttons (their actions are released).
func release_all() -> void:
	_stick_touch = -1
	_stick = Vector2.ZERO
	_apply_stick()
	_look_touch = -1
	_mouse_down = false
	for button in _buttons:
		if button.touch >= 0:
			button.touch = -1
			_send(button.action, false)


func button_center(action: String) -> Vector2:
	for button in _buttons:
		if button.action == action:
			return _size + button.at
	return Vector2.INF


func stick_home() -> Vector2:
	return Vector2(maxf((_size.x - 320.0) / 4.0, 44.0), _size.y - 50.0)


# ---- Input

func _input(event: InputEvent) -> void:
	if not _shown:
		return
	if event is InputEventMouse:
		if DisplayServer.is_touchscreen_available() or event.device == InputEvent.DEVICE_ID_EMULATION:
			return # a real touchscreen sends its own touches; these are copies
		event = _mouse_to_touch(event)
		if event == null:
			return
	var touch := event as InputEventScreenTouch
	if touch:
		if touch.pressed:
			_on_press(touch.index, touch.position)
		else:
			_on_release(touch.index)
		get_viewport().set_input_as_handled()
		return
	var drag := event as InputEventScreenDrag
	if drag:
		_on_drag(drag.index, drag.position, drag.relative)
		get_viewport().set_input_as_handled()


func _mouse_to_touch(event: InputEvent) -> InputEvent:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT:
		_mouse_down = click.pressed
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.pressed = click.pressed
		touch.position = click.position
		return touch
	var motion := event as InputEventMouseMotion
	if motion and _mouse_down:
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = motion.position
		drag.relative = motion.relative
		return drag
	return null


func _on_press(index: int, at: Vector2) -> void:
	for button in _buttons:
		if button.touch < 0 and at.distance_to(_size + button.at) <= button.radius + SLOP:
			button.touch = index
			_send(button.action, true)
			return
	if at.x < _size.x * 0.5:
		if _stick_touch < 0:
			_stick_touch = index
			_stick_center = Vector2(clampf(at.x, STICK_RADIUS + 2.0, _size.x * 0.5 - STICK_RADIUS),
				clampf(at.y, STICK_RADIUS + 2.0, _size.y - STICK_RADIUS - 2.0))
			_stick = Vector2.ZERO
			_on_drag(index, at, Vector2.ZERO)
	elif _look_touch < 0:
		_look_touch = index


func _on_release(index: int) -> void:
	if index == _stick_touch:
		_stick_touch = -1
		_stick = Vector2.ZERO
		_apply_stick()
	elif index == _look_touch:
		_look_touch = -1
	else:
		for button in _buttons:
			if button.touch == index:
				button.touch = -1
				_send(button.action, false)


func _on_drag(index: int, at: Vector2, relative: Vector2) -> void:
	if index == _stick_touch:
		_stick = ((at - _stick_center) / STICK_RADIUS).limit_length(1.0)
		_apply_stick()
	elif index == _look_touch and player:
		var settings := _settings()
		var sensitivity: float = settings.values.get("touch_look", 0.012) if settings else 0.012
		player.look_by(-relative.x * sensitivity, -relative.y * sensitivity)


## Stick -> move_* strengths (read by Input.get_vector in the Player) and sprint at the rim.
func _apply_stick() -> void:
	var v := _stick if _stick.length() >= DEAD_ZONE else Vector2.ZERO
	_set_axis("move_left", maxf(-v.x, 0.0))
	_set_axis("move_right", maxf(v.x, 0.0))
	_set_axis("move_forward", maxf(-v.y, 0.0))
	_set_axis("move_back", maxf(v.y, 0.0))
	_set_axis("sprint", 1.0 if v.length() >= SPRINT_AT else 0.0)


func _set_axis(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
		_held_axes[action] = true
	elif _held_axes.has(action):
		_held_axes.erase(action)
		Input.action_release(action)


## Fires the action as a real input event, so `_unhandled_input` handlers (overlay) see it too.
func _send(action: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(event)


# ---- Drawing

func _available(action: String) -> bool:
	match action:
		"flashlight":
			return GameState.has_flashlight
		"radio":
			return GameState.has_radio
		"journal":
			return GameState.book_read
	return true


func _paint(canvas: Control) -> void:
	var home := _stick_center if _stick_touch >= 0 else stick_home()
	var sprint := _stick.length() >= SPRINT_AT
	canvas.draw_circle(home, STICK_RADIUS, Color(UiKit.INK, 0.45))
	canvas.draw_arc(home, STICK_RADIUS, 0.0, TAU, 32, UiKit.BLOOD if sprint else UiKit.BRASS, 1.0)
	canvas.draw_arc(home, STICK_RADIUS - 3.0, 0.0, TAU, 32, Color(UiKit.RUST, 0.8), 1.0)
	var knob := home + _stick * STICK_RADIUS
	canvas.draw_circle(knob, KNOB_RADIUS, UiKit.BRASS.darkened(0.35) if _stick_touch >= 0 else Color(UiKit.BRASS.darkened(0.5), 0.8))
	canvas.draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 20, UiKit.BRASS, 1.0)

	for button in _buttons:
		var center: Vector2 = _size + button.at
		var radius: float = button.radius
		var down: bool = button.touch >= 0
		var lit: bool = button.action == "interact" and _focused
		var face := Color(0.3, 0.06, 0.05, 0.7) if down else Color(0.05, 0.08, 0.075, 0.55)
		canvas.draw_circle(center, radius, face)
		canvas.draw_arc(center, radius, 0.0, TAU, 28, UiKit.BRASS if (down or lit) else Color(UiKit.BRASS, 0.6), 1.0)
		var tint := Color.WHITE if _available(button.action) else Color(1, 1, 1, 0.35)
		var texture: Texture2D = button.icon
		canvas.draw_texture(texture, (center - texture.get_size() / 2.0).floor(), tint)
		if button.action == "interact" and _hold > 0.0:
			canvas.draw_arc(center, radius + 2.0, -PI / 2.0, -PI / 2.0 + TAU * _hold, 28, UiKit.BLOOD.lightened(0.2), 2.0)


class Canvas extends Control:
	var hud ## the owning TouchControls

	func _draw() -> void:
		hud._paint(self)
