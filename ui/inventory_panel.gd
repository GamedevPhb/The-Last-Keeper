class_name InventoryPanel
extends "res://ui/puzzle_console.gd"
## The Tab / Triangle screen (GDD 4.9): an 8x4 grid of slots that works like Minecraft's,
## the three status bars (GDD 4.10) on the right and the hovered item's description below.
## The night keeps running. State lives in `GameState.inventory`; this only draws and routes.
## Mouse: left picks up / places / merges / swaps, right takes half or places one,
## Shift+left uses, Q or a click off the grid drops. Pad: stick/d-pad moves, X picks/places,
## Square uses, Circle drops, R1 splits, Triangle closes. Keys: arrows/WASD, Space, E, Q, F, Tab.
## Touch: tap picks up / places, holding a slot splits it, USAR / LARGAR act on the selected slot.

const LAMP := preload("res://ui/lamp_console.gd")
const FUSE := preload("res://ui/fuse_console.gd")
const SLOT := 26
const GAP := 2
const COLUMNS := 8
const ROWS := 4
const HELP_KEYS := "Clique pega · Dir. divide · Shift usa · Q larga · Tab fecha"
const SPLIT_HOLD := 0.45 ## seconds a finger stays on a slot to split it
const HELP_PAD := "X pega · R1 divide · Quadrado usa · Círculo larga · Triângulo fecha"

const ITEM_ICONS := {
	"flashlight": [
		"",
		"",
		"",
		"..........kkk",
		".........kwwwk",
		".kkkkkkkkkwyywk",
		"kbbbbbbbbkwyyywk",
		"kblllllbbkwyyywk",
		"kbbbbbbbbkwyyywk",
		".kkkkkkkkkwyywk",
		".........kwwwk",
		"..........kkk",
	],
	"fuel": [
		"",
		"...kkkkk",
		"..krrrrrk.kk",
		"..kkkkkkkkdk",
		".krrrrrrrrrk",
		".krrkkkkkrrk",
		".krkrrrrrkrk",
		".krkrrrrrkrk",
		".krrkrrrkrrk",
		".krrrkrkrrrk",
		".krrkrrrkrrk",
		".krkrrrrrkrk",
		".krrrrrrrrrk",
		".kddddddddddk",
		"..kkkkkkkkkk",
	],
	"water": [
		"......kkk",
		"......kdk",
		"......kdk",
		".....kcck",
		".....kcck",
		"....kccsck",
		"...kcccscck",
		"...kccccsck",
		"...kBBBBBBk",
		"...kBBcBBBk",
		"...kBBBBBBk",
		"...kBBBBcBk",
		"...kBBBBBBk",
		"...kBBBBBBk",
		"....kkkkkk",
	],
	"can": [
		"",
		"",
		"...kkkkkkkkk",
		"..kgwwwwwwwgk",
		"..kkkkkkkkkkk",
		"..kgggggggggk",
		"..krrrrrrrrrk",
		"..krwwrrrwwrk",
		"..krwwwrwwwrk",
		"..krrrrrrrrrk",
		"..kgggggggggk",
		"..kkkkkkkkkkk",
		"...kkkkkkkkk",
	],
	"biscuit": [
		"",
		"",
		"",
		"...kkkkkkkk",
		"..kbbbbbbbbk",
		".kbbdbbbdbbbk",
		".kbbbbbbbbbbk",
		".kbbbdbbbdbbk",
		".kbbbbbbbbbbk",
		".kbdbbbdbbbbk",
		"..kbbbbbbbbk",
		"...kkkkkkkk",
	],
	"bandage": [
		"",
		"",
		"....kkkkkkk",
		"...kwwwwwwwk",
		"..kwwwwrwwwwk",
		"..kwwwwrwwwwk",
		"..kwwrrrrrwwk",
		"..kwwwwrwwwwk",
		"..kwwwwrwwwwk",
		"..kgwwwwwwwgk",
		"...kgggggggk",
		"....kkkkkkk",
	],
}
## 8x8 status icons, shared with the HUD's critical markers.
const STATUS_ICONS := {
	"thirst": [
		"...kk",
		"..kcck",
		"..kcck",
		".kccBck",
		".kcBBck",
		"kcBBBBck",
		".kBBBBk",
		"..kkkk",
	],
	"hunger": [
		"..kkkk",
		".kbbbbk",
		"kbbdbbbk",
		"kbbbbdbk",
		"kbdbbbbk",
		".kbbbbk",
		"..kkkk",
	],
	"health": [
		".kk..kk",
		"krrkkrrk",
		"krrrrrrk",
		"krrrrrrk",
		".krrrrk",
		"..krrk",
		"...kk",
	],
}
const STATUS_COLORS := {"thirst": Color(0.35, 0.6, 0.95), "hunger": Color(0.9, 0.6, 0.2), "health": Color(0.8, 0.15, 0.12)}

var _textures := {}
var _grid: Grid
var _status: StatusColumn
var _cursor_view: CursorView
var _name: Label
var _desc: Label
var _bar: ProgressBar
var _hover_slot := -1
var _mouse_mode := true
var _pad := false
## Slot under a finger that has not lifted yet (tap = left, hold = split), and for how long.
var _press_slot := -1
var _press_time := 0.0
## A consumable being eaten / drunk / applied: {id, left, total}.
var _using := {}


static func item_texture(id: String) -> ImageTexture:
	if ITEM_ICONS.has(id):
		return icon(ITEM_ICONS[id])
	if id == "oil":
		return icon(LAMP.ICONS[0])
	if id == "radio":
		return icon(FUSE.ICONS.radio)
	return icon(["kkkk", "kwwk", "kwwk", "kkkk"])


static func status_texture(key: String) -> ImageTexture:
	return icon(STATUS_ICONS[key], 8)


func texture_for(id: String) -> ImageTexture:
	if not _textures.has(id):
		_textures[id] = item_texture(id)
	return _textures[id]


func _action_count() -> int:
	return COLUMNS * ROWS


func _help_text() -> String:
	return HELP_PAD if _pad else HELP_KEYS


func _build_body(body: VBoxContainer) -> void:
	_title.text = "INVENTÁRIO"
	_top.add_child(_touch_button("USAR", func() -> void: use_slot(_focus)))
	_top.add_child(_touch_button("LARGAR", func() -> void: drop(_focus)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	_grid = Grid.new()
	_grid.panel = self
	_grid.custom_minimum_size = Vector2(COLUMNS * (SLOT + GAP) - GAP, ROWS * (SLOT + GAP) - GAP)
	row.add_child(_grid)
	_status = StatusColumn.new()
	_status.custom_minimum_size = Vector2(64, _grid.custom_minimum_size.y)
	for key: String in STATUS_ICONS:
		_status.icons[key] = status_texture(key)
	row.add_child(_status)
	body.add_child(row)
	_name = UiKit.label("", 0, UiKit.BRASS)
	body.add_child(_name)
	_desc = UiKit.label("", 292)
	_desc.custom_minimum_size.y = 21
	body.add_child(_desc)
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(292, 3)
	_bar.show_percentage = false
	_bar.max_value = 1.0
	var groove := UiKit.style(UiKit.INK, UiKit.RUST)
	groove.set_content_margin_all(0)
	_bar.add_theme_stylebox_override("background", groove)
	var fill := StyleBoxFlat.new()
	fill.bg_color = UiKit.SEA
	_bar.add_theme_stylebox_override("fill", fill)
	body.add_child(_bar)


func _ready() -> void:
	super()
	_cursor_view = CursorView.new()
	_cursor_view.panel = self
	_cursor_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cursor_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_cursor_view)
	# Clicking off the grid while holding a stack drops it (Minecraft).
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_off_grid)
	_panel.gui_input.connect(_on_off_grid)


func open(by: Player = null) -> void:
	super(by)
	_hover_slot = -1
	_press_slot = -1
	_using = {}


func close() -> void:
	if not visible:
		return
	_using = {}
	var rest: Dictionary = GameState.inventory.stow_cursor()
	if not rest.is_empty():
		GameState.inventory.take_cursor()
		GameState.drop_item(rest.id, rest.count)
	super()


# ---- Actions (mouse, keys, pad and tests all land here)

func left(index: int) -> void:
	GameState.inventory.left(index)
	GameState.play("inv_click")


func right(index: int) -> void:
	GameState.inventory.right(index)
	GameState.play("inv_click")


## Uses the item in a slot: consumables take 2-4 s (the night keeps running).
func use_slot(index: int) -> void:
	var slot: Dictionary = GameState.inventory.slots[index]
	if slot.is_empty():
		return
	var item: Dictionary = GameState.INVENTORY.ITEMS.get(slot.id, {})
	match item.get("use", ""):
		"consume":
			if _using.is_empty():
				_using = {"id": slot.id, "left": item.time, "total": item.time}
				GameState.play("inv_click")
		"flashlight":
			GameState.request_flashlight()
		"radio":
			close()
			GameState.request_radio()
		"console":
			GameState.say(item.console)


## Drops the held stack, or one item from the slot under the cursor.
func drop(index := -1) -> void:
	var inventory = GameState.inventory
	if not inventory.cursor.is_empty():
		var held: Dictionary = inventory.take_cursor()
		GameState.drop_item(held.id, held.count)
		return
	if index < 0:
		index = _active_slot()
	if index < 0:
		return
	var taken: Dictionary = inventory.take_at(index, 1)
	if not taken.is_empty():
		GameState.drop_item(taken.id, taken.count)


func tick_use(delta: float) -> void:
	if _using.is_empty():
		return
	_using.left -= delta
	if _using.left <= 0.0:
		var id: String = _using.id
		_using = {}
		if not GameState.consume(id):
			GameState.say("Acabou.")


func _active_slot() -> int:
	return _hover_slot if _mouse_mode and _hover_slot >= 0 else _focus


func _hold_tick(_delta: float) -> void:
	pass


func _refresh() -> void:
	tick_use(get_process_delta_time())
	if _press_slot >= 0:
		_press_time += get_process_delta_time()
		if _press_time >= SPLIT_HOLD:
			right(_press_slot)
			_press_slot = -1
	var heavy: bool = GameState.oil_cans + GameState.fuel_cans >= GameState.HEAVY_CANS
	_header.text = "PESADO: sem corrida" if heavy else ""
	_header.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	var slot: Dictionary = GameState.inventory.slots[clampi(_active_slot(), 0, 31)] if _active_slot() >= 0 else {}
	if slot.is_empty():
		_name.text = ""
		_desc.text = "Vazio." if _active_slot() >= 0 else ""
	else:
		var item: Dictionary = GameState.INVENTORY.ITEMS.get(slot.id, {})
		_name.text = "%s  x%d" % [item.get("name", slot.id), slot.count]
		_desc.text = item.get("desc", "")
	_bar.value = 0.0 if _using.is_empty() else 1.0 - _using.left / _using.total
	_status.values = {"thirst": GameState.thirst, "hunger": GameState.hunger, "health": GameState.health}
	_status.queue_redraw()
	_grid.queue_redraw()
	_cursor_view.queue_redraw()
	_help.text = _help_text()


func _style_buttons() -> void:
	pass


# ---- Input

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouse:
		if event is InputEventMouseMotion and not TouchControls.enabled:
			_mouse_mode = true
		return
	var pad := event is InputEventJoypadButton or event is InputEventJoypadMotion
	if event is InputEventKey or pad:
		if event.is_pressed() and not event.is_echo():
			_pad = pad
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		if key.physical_keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()
			return
		if key.physical_keycode == KEY_Q:
			drop()
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("pause"):
		close()
		return
	if event.is_action_pressed("inventory"):
		close()
	elif pad and event.is_action_pressed("ui_cancel"):
		drop(_focus)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_move(-1, 0)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_move(1, 0)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_forward"):
		_move(0, -1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_back"):
		_move(0, 1)
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		_mouse_mode = false
		left(_focus)
	elif event.is_action_pressed("interact"):
		_mouse_mode = false
		use_slot(_focus)
	elif event.is_action_pressed("flashlight"):
		_mouse_mode = false
		right(_focus)
	else:
		return
	get_viewport().set_input_as_handled()


func _move(dx: int, dy: int) -> void:
	_mouse_mode = false
	var col := posmod(_focus % COLUMNS + dx, COLUMNS)
	var row := posmod(floori(_focus / float(COLUMNS)) + dy, ROWS)
	_focus = row * COLUMNS + col


func _on_grid_click(index: int, button: MouseButton, shift: bool) -> void:
	_mouse_mode = true
	_hover_slot = index
	if button == MOUSE_BUTTON_LEFT:
		if shift:
			use_slot(index)
		else:
			left(index)
	elif button == MOUSE_BUTTON_RIGHT:
		right(index)


## Touch: a finger lands on a slot; it becomes the selection and waits to see tap or hold.
func touch_down(index: int) -> void:
	_mouse_mode = false
	_focus = index
	_press_slot = index
	_press_time = 0.0


## The finger lifted before the split: a tap picks up or places, like a left click.
func touch_up() -> void:
	if _press_slot >= 0:
		left(_press_slot)
		_press_slot = -1


func _on_off_grid(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and not GameState.inventory.cursor.is_empty():
		drop()


func slot_rect(index: int) -> Rect2:
	return Rect2((index % COLUMNS) * (SLOT + GAP), floori(index / float(COLUMNS)) * (SLOT + GAP), SLOT, SLOT)


## Draws a stack: icon centred in a slot-sized rect, count in the bottom-right corner.
func draw_stack(canvas: Control, rect: Rect2, stack: Dictionary) -> void:
	if stack.is_empty():
		return
	var icon_rect := Rect2(rect.position + (rect.size - Vector2(16, 16)) / 2.0, Vector2(16, 16))
	canvas.draw_texture_rect(texture_for(stack.id), icon_rect, false)
	if stack.count > 1:
		var font := canvas.get_theme_default_font()
		var text := str(stack.count)
		var at := rect.position + Vector2(rect.size.x - 2.0 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE).x, rect.size.y - 2.0)
		canvas.draw_string(font, at + Vector2.ONE, text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.INK)
		canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.BONE)


## The 8x4 slot grid: draws every slot and turns clicks into slot actions.
class Grid extends Control:
	var panel ## the owning InventoryPanel

	func _gui_input(event: InputEvent) -> void:
		var index := _index_at(get_local_mouse_position())
		if event is InputEventMouseMotion and not TouchControls.enabled:
			panel._mouse_mode = true
			panel._hover_slot = index
		var click := event as InputEventMouseButton
		if click and TouchControls.enabled and click.button_index == MOUSE_BUTTON_LEFT and not click.shift_pressed:
			if not click.pressed:
				panel.touch_up()
			elif index < 0:
				panel._on_off_grid(event)
			else:
				panel.touch_down(index)
			accept_event()
			return
		if click and click.pressed:
			if index < 0:
				panel._on_off_grid(event)
			else:
				panel._on_grid_click(index, click.button_index, click.shift_pressed)
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_EXIT and panel:
			panel._hover_slot = -1

	func _index_at(point: Vector2) -> int:
		for i in COLUMNS * ROWS:
			if panel.slot_rect(i).has_point(point):
				return i
		return -1

	func _draw() -> void:
		var slots: Array = GameState.inventory.slots
		for i in slots.size():
			var rect: Rect2 = panel.slot_rect(i)
			var lit: bool = i == panel._hover_slot if panel._mouse_mode else i == panel._focus
			draw_rect(rect, UiKit.INK)
			draw_rect(rect.grow(-1), Color(0.2, 0.26, 0.22) if lit else Color(0.12, 0.17, 0.15))
			# Bevel: dark top-left, brass bottom-right, like a pressed brass socket.
			draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(rect.size.x - 2, 1)), Color(0.03, 0.05, 0.05))
			draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(1, rect.size.y - 2)), Color(0.03, 0.05, 0.05))
			draw_rect(Rect2(rect.position + Vector2(1, rect.size.y - 2), Vector2(rect.size.x - 2, 1)), UiKit.RUST.lightened(0.2))
			if lit:
				draw_rect(rect, UiKit.BRASS, false, 1.0)
			panel.draw_stack(self, rect, slots[i])


## The held stack, drawn over everything: at the mouse, or over the focused slot on pad/keys.
class CursorView extends Control:
	var panel ## the owning InventoryPanel

	func _draw() -> void:
		var held: Dictionary = GameState.inventory.cursor
		if held.is_empty():
			return
		var at: Vector2
		if panel._mouse_mode:
			at = get_local_mouse_position() - Vector2(13, 13)
		else:
			var grid_rect: Rect2 = panel._grid.get_global_rect()
			at = grid_rect.position + panel.slot_rect(panel._focus).position + Vector2(6, -8) - get_global_rect().position
		panel.draw_stack(self, Rect2(at, Vector2(26, 26)), held)


## Thirst, hunger and health: vertical bars without numbers and a risk line at 20.
class StatusColumn extends Control:
	var values := {"thirst": 0.0, "hunger": 0.0, "health": 0.0}
	var icons := {}

	func _draw() -> void:
		var x := 6.0
		var top := 12.0
		var height := size.y - top - 2.0
		for key: String in ["thirst", "hunger", "health"]:
			if icons.has(key):
				draw_texture(icons[key], Vector2(x + 1, 0))
			var bar := Rect2(x, top, 10, height)
			draw_rect(bar, UiKit.INK)
			draw_rect(bar.grow(-1), Color(0.05, 0.08, 0.075))
			var fill := clampf(values[key] / 100.0, 0.0, 1.0) * (height - 2.0)
			var color: Color = STATUS_COLORS[key]
			if values[key] <= (30.0 if key == "health" else 20.0):
				color = color.lightened(0.3)
			draw_rect(Rect2(x + 1, top + height - 1.0 - fill, 8, fill), color)
			var risk := top + height - 1.0 - 0.2 * (height - 2.0)
			draw_line(Vector2(x - 2, risk), Vector2(x + 12, risk), UiKit.BLOOD, 1.0)
			x += 20.0
