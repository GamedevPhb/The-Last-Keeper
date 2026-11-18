class_name Hud
extends CanvasLayer
## Lean HUD: crosshair dot, clock, and things that appear only when they matter.
## The objective (with distance and heading) shows for a few seconds when it changes, the
## inventory strip when it changes, messages fade on their own, the interaction prompt sits
## in the lower third, and the whole HUD hides while a puzzle panel is open
## (`GameState.panel_changed`), since panels show their own messages.
## The hotbar (first inventory row, `Hotbar` below) sits at the bottom centre, always on while
## playing, with the selected slot in brass and its name popping up for a moment on change.
## It also owns the touch controls (`ui/touch_controls.gd`), which show only on touch devices.

const OBJECTIVE_TIME := 8.0
const STATUS_TIME := 5.0
const HINTS_TIME := 8.0
const FADE := 1.0
const INVENTORY_PANEL := preload("res://ui/inventory_panel.gd")
const HOTBAR_NAME_TIME := 2.0

@export var player: Player

var _target: Interactable
var _toast_left := 0.0
var _objective_left := 0.0
var _status_left := 0.0
var _hints_left := HINTS_TIME
var _last_objective := ""
var _last_status := ""
var _gamepad := false
## 8x8 critical-status icons, bottom-left, only while a status is critical (GDD 4.10).
var _critical_icons := {}
var _blink := 0.0
## Phone icon + time bar, top-right. Lives outside `_root` so it stays while a panel hides the HUD.
var _phone_box: Control
var _phone_icon: TextureRect
var _phone_bar: ColorRect
## Flashlight charge, bottom-right, only while the beam is on.
var _battery: Label
## Weapon in hand and its ammo ("Pistola 6/12"), bottom-right above the battery.
var _ammo: Label
## "Onda 2/3 · restam 5", top-center, only while the invasion runs.
var _wave: Label
## Bottom-centre row of the 8 hotbar slots, and the selected item's name above it.
var _hotbar: Hotbar
var _hotbar_name: Label
var _hotbar_name_left := 0.0

@onready var _root: Control = $Root
@onready var _prompt: Label = $Root/Prompt
@onready var _hold_bar: ProgressBar = $Root/HoldBar
@onready var _toast: Label = $Root/Toast
@onready var _status: Label = $Root/Status
@onready var _objective: Label = $Root/Objective
@onready var _compass: Label = $Root/Compass
@onready var _clock: Label = $Root/Clock
@onready var _hints: Label = $Root/Hints


func _ready() -> void:
	player.focus_changed.connect(_on_focus_changed)
	player.hold_progress_changed.connect(_on_hold_progress_changed)
	GameState.toast.connect(_on_toast)
	GameState.changed.connect(_refresh_status)
	GameState.panel_changed.connect(_on_panel_changed)
	_toast.text = ""
	_build_frames()
	_on_focus_changed(null)
	_on_hold_progress_changed(0.0)
	_toast.visible = false
	_compass.visible = false # the heading now rides on the objective line
	_refresh_status()
	_update_hints()
	_build_phone()
	var touch := TouchControls.new()
	touch.name = "TouchControls"
	touch.player = player
	add_child(touch)
	get_viewport().size_changed.connect(_layout)
	_layout()
	_battery = UiKit.label("", 0, UiKit.BRASS)
	_battery.visible = false
	_root.add_child(_battery)
	_tag(_battery, Vector2(1.0, 1.0), Vector2(-2.0, -1.0))
	_ammo = UiKit.label("", 0, UiKit.BRASS)
	_ammo.visible = false
	_root.add_child(_ammo)
	_tag(_ammo, Vector2(1.0, 1.0), Vector2(-2.0, -16.0))
	_wave = UiKit.label("", 0, UiKit.BLOOD.lightened(0.4))
	_wave.visible = false
	_root.add_child(_wave)
	_tag(_wave, Vector2(0.5, 0.0), Vector2(0.0, 18.0))
	_build_hotbar()
	var x := 4.0
	for key: String in ["thirst", "hunger", "health"]:
		var icon := TextureRect.new()
		icon.texture = INVENTORY_PANEL.status_texture(key)
		icon.position = Vector2(x, 228)
		icon.size = Vector2(8, 8)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.visible = false
		_root.add_child(icon)
		_critical_icons[key] = icon
		x += 10.0


func _build_hotbar() -> void:
	_hotbar = Hotbar.new()
	_hotbar.name = "Hotbar"
	_hotbar.size = Vector2(Hotbar.WIDTH, Hotbar.SLOT)
	_root.add_child(_hotbar)
	_hotbar_name = UiKit.label("", 0, UiKit.CREAM)
	_hotbar_name.name = "HotbarName"
	_hotbar_name.visible = false
	_root.add_child(_hotbar_name)
	_tag(_hotbar_name, Vector2(0.5, 1.0), Vector2(0.0, -(Hotbar.SLOT + 2.0)))
	GameState.hotbar_changed.connect(_on_hotbar_changed)
	GameState.changed.connect(_hotbar.queue_redraw)
	GameState.weapon_changed.connect(_hotbar.queue_redraw)
	_layout()


func _on_hotbar_changed() -> void:
	_hotbar.queue_redraw()
	var id: String = GameState.held_item()
	_hotbar_name.text = GameState.INVENTORY.item_name(id) if id != "" else "Mãos vazias"
	_hotbar_name_left = HOTBAR_NAME_TIME
	_hints_left = 0.0 # the name takes the hints' line


func _build_phone() -> void:
	var rows := [
		"..kkkkkkkk..",
		".kssssssssk.",
		".kskkkkkksk.",
		"..kk....kk..",
		"..kk....kk..",
		".kssk..kssk.",
		".kssk..kssk.",
		"..kk....kk..",
	]
	var image := Image.create(12, 8, false, Image.FORMAT_RGBA8)
	for y in rows.size():
		for x in 12:
			var c: String = rows[y][x]
			image.set_pixel(x, y, Color.BLACK if c == "k" else (Color(0.95, 0.85, 0.35) if c == "s" else Color(0, 0, 0, 0)))
	_phone_box = Control.new()
	_phone_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_box.size = Vector2(16, 14)
	_phone_box.visible = false
	add_child(_phone_box)
	_phone_icon = TextureRect.new()
	_phone_icon.texture = ImageTexture.create_from_image(image)
	_phone_icon.size = Vector2(12, 8)
	_phone_icon.position = Vector2(2, 0)
	_phone_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_box.add_child(_phone_icon)
	var back := ColorRect.new()
	back.color = Color(0, 0, 0, 0.7)
	back.position = Vector2(0, 10)
	back.size = Vector2(16, 3)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_box.add_child(back)
	_phone_bar = ColorRect.new()
	_phone_bar.position = Vector2(1, 11)
	_phone_bar.size = Vector2(14, 1)
	_phone_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phone_box.add_child(_phone_bar)


## Blinks while the phone rings, steady once answered; the bar is the wait left.
func _update_phone() -> void:
	var call: Dictionary = GameState.active_call
	_phone_box.visible = not call.is_empty() and GameState.in_game and not GameState.dead
	if not _phone_box.visible:
		return
	var ratio := clampf(call.left / call.get("total", 30.0), 0.0, 1.0) if call.has("left") else 0.0
	_phone_bar.size.x = 14.0 * ratio
	_phone_bar.color = UiKit.BLOOD if ratio < 0.3 else UiKit.BRASS
	_phone_icon.modulate.a = (1.0 if int(_blink * 3.0) % 2 == 0 else 0.25) if GameState.ringing else 1.0


func _build_frames() -> void:
	# Legibility (tester feedback): every HUD text sits on a near-black plate with a 1 px shadow,
	# in cream/brass at UiKit.FONT_SIZE. Multi-line texts get a themed strip behind them; one-line
	# ones carry the plate as their own stylebox (`_tag`), so it hugs the text.
	# Objective (top-left, grows down) and toast (bottom, grows up above the hints) wrap at a fixed
	# width and carry the strip as their own stylebox, so it always fits the line count.
	for label: Label in [_objective, _toast]:
		label.add_theme_stylebox_override("normal", _strip())
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.anchor_right = 0.0
	_objective.anchor_bottom = 0.0
	_objective.offset_left = 2.0
	_objective.offset_right = 178.0
	_objective.offset_top = 18.0
	_objective.offset_bottom = 18.0
	_toast.offset_top = -37.0
	_toast.offset_bottom = -37.0
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Prompt and hold bar sit below the crosshair, clear of it; toast, hints and the hotbar stack
	# below them down to the bottom edge.
	_tag(_status, Vector2.ZERO, Vector2(2.0, 2.0))
	_tag(_clock, Vector2(1.0, 0.0), Vector2(-2.0, 2.0))
	_tag(_prompt, Vector2(0.5, 0.5), Vector2(0.0, 28.0))
	_tag(_hints, Vector2(0.5, 1.0), Vector2(0.0, -21.0))
	_hold_bar.offset_top = 44.0
	_hold_bar.offset_bottom = 46.0
	_clock.add_theme_color_override("font_color", UiKit.BRASS)
	_hints.add_theme_color_override("font_color", UiKit.MUTED)
	for label: Label in [_objective, _toast, _compass]:
		label.add_theme_constant_override("outline_size", 0)


## Puts `label` on its own dark plate (`UiKit.tag()`) sized to its text. `anchor` is the point of
## the screen it hangs from and `offset` its distance (in pixels) from it; the plate grows away from
## the nearest edge (left/right/both ways, down from the top or up from the bottom).
func _tag(label: Label, anchor: Vector2, offset: Vector2) -> void:
	label.add_theme_stylebox_override("normal", UiKit.tag())
	label.add_theme_constant_override("outline_size", 0)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_left = anchor.x
	label.anchor_right = anchor.x
	label.anchor_top = anchor.y
	label.anchor_bottom = anchor.y
	label.offset_left = offset.x
	label.offset_right = offset.x
	label.offset_top = offset.y
	label.offset_bottom = offset.y
	label.grow_horizontal = Control.GROW_DIRECTION_END if anchor.x < 0.25 else (Control.GROW_DIRECTION_BEGIN if anchor.x > 0.75 else Control.GROW_DIRECTION_BOTH)
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN if anchor.y > 0.75 else Control.GROW_DIRECTION_END


## Centres the strips on wide screens (aspect "expand" on phones); 320 wide keeps the PC layout.
func _layout() -> void:
	var margin := (get_viewport().get_visible_rect().size.x - 280.0) / 2.0
	_phone_box.position = Vector2(get_viewport().get_visible_rect().size.x - 20.0, 18.0)
	_toast.offset_left = margin
	_toast.offset_right = -margin
	if _hotbar:
		var view := get_viewport().get_visible_rect().size
		_hotbar.position = Vector2(floorf((view.x - Hotbar.WIDTH) / 2.0), view.y - Hotbar.SLOT - 1.0)


## The HUD strip (`UiKit.bar()`) with roomier side margins, for the wrapped objective and toast.
func _strip() -> StyleBox:
	var box := UiKit.bar()
	box.content_margin_left = 5
	box.content_margin_right = 5
	return box


func _process(delta: float) -> void:
	_clock.text = GameState.clock_text()
	var objective := GameState.objective()
	if objective != _last_objective:
		_last_objective = objective
		_objective_left = OBJECTIVE_TIME
	if _objective_left > 0.0:
		_objective_left -= delta
		_objective.text = objective + _target_line()
	_fade(_objective_left, [_objective])
	_toast_left -= delta
	_fade(_toast_left, [_toast])
	_status_left -= delta
	_fade(_status_left, [_status])
	_hints_left -= delta
	_fade(0.0 if TouchControls.enabled else _hints_left, [_hints])
	_blink += delta
	_update_phone()
	_update_battery()
	_update_ammo()
	_hotbar.visible = GameState.in_game and not GameState.dead and not GameState.finished
	_hotbar.mouse_filter = Control.MOUSE_FILTER_STOP if TouchControls.enabled else Control.MOUSE_FILTER_IGNORE
	_hotbar_name_left -= delta
	_fade(_hotbar_name_left if _hotbar.visible else 0.0, [_hotbar_name])
	_wave.visible = GameState.invasion_active and GameState.invasion_wave > 0
	if _wave.visible:
		_wave.text = "Onda %d/3 · restam %d" % [GameState.invasion_wave, GameState.invasion_left]
	var critical: Dictionary = GameState.critical()
	for key: String in _critical_icons:
		var icon: TextureRect = _critical_icons[key]
		icon.visible = critical[key] and not _hints.visible
		icon.modulate.a = 0.55 + 0.45 * sin(_blink * 2.0)
	# Prompts change while focused (e.g. a counter in the text), so poll them.
	if _target:
		_prompt.text = _target.prompt if TouchControls.enabled else "[%s] %s" % ["Quadrado" if _gamepad else "E", _target.prompt]


## "Pilha 80%" while the beam is on; blinks when low, "+" marks the lens boost.
func _update_battery() -> void:
	var charge: float = GameState.flashlight_battery
	_battery.visible = GameState.flashlight_on
	_battery.text = "Pilha %d%%%s" % [ceili(charge), " +" if GameState.lens_left > 0.0 else ""]
	var low := charge < GameState.FLASH_LOW
	_battery.add_theme_color_override("font_color", UiKit.BLOOD.lightened(0.4) if low and fmod(_blink, 1.0) < 0.5 else UiKit.BRASS)


## "Pistola 6/12" (magazine / spare rounds), "recarregando" while reloading, just the name for the axe.
func _update_ammo() -> void:
	var id: String = GameState.equipped
	_ammo.visible = id != ""
	if id == "":
		return
	var def: Dictionary = GameState.WEAPON_DEFS.get_def(id)
	if not def.ranged:
		_ammo.text = def.name
		return
	var weapons := player.get_node_or_null("Head/Camera3D/Weapons") if player else null
	var reloading: bool = weapons != null and weapons.is_reloading()
	var mag: int = GameState.mags[id]
	_ammo.text = "%s %s" % [def.name, "recarregando..." if reloading else "%d/%d" % [mag, GameState.reserve_ammo(id)]]
	var empty := mag <= 0 and not reloading
	_ammo.add_theme_color_override("font_color", UiKit.BLOOD.lightened(0.4) if empty else UiKit.BRASS)


## Shows `items` while `left` > 0, fading out over the last second.
func _fade(left: float, items: Array) -> void:
	for item: CanvasItem in items:
		item.visible = left > 0.0
		item.modulate.a = clampf(left / FADE, 0.0, 1.0)


func _on_panel_changed(open: bool) -> void:
	_root.visible = not open
	if not open:
		_objective_left = maxf(_objective_left, 3.0)


func _on_focus_changed(target: Interactable) -> void:
	_target = target
	_prompt.visible = target != null


func _on_hold_progress_changed(ratio: float) -> void:
	_hold_bar.value = ratio
	_hold_bar.visible = ratio > 0.0


func _on_toast(text: String) -> void:
	_toast.text = text
	_toast_left = clampf(2.5 + text.length() * 0.035, 3.0, 6.0)


func _refresh_status() -> void:
	var text := "Óleo %d  Comb. %d  Navios %d/%d%s" % [
		GameState.oil_cans, GameState.fuel_cans, GameState.ships_saved,
		GameState.ships_saved + GameState.ships_lost, "  [gerador]" if GameState.generator_on else ""]
	if text != _last_status:
		_last_status = text
		_status.text = text
		_status_left = STATUS_TIME


func _heading() -> String:
	var forward := -player.global_transform.basis.z
	var degrees := rad_to_deg(atan2(forward.x, -forward.z))
	return ["N", "NE", "L", "SE", "S", "SO", "O", "NO"][posmod(roundi(degrees / 45.0), 8)]


func _input(event: InputEvent) -> void:
	var pad := event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5)
	var keys := event is InputEventKey or event is InputEventMouseButton
	if (pad and not _gamepad) or (keys and _gamepad):
		_gamepad = pad
		_update_hints()
		_hints_left = HINTS_TIME


func _update_hints() -> void:
	# One line that fits 320 px at UiKit.FONT_SIZE (Options needs no hint on the pad).
	_hints.text = "[Triângulo] Inventário  [↑] Rádio  [L1] Livro  [R1] Lanterna" if _gamepad else "[Tab] Inventário  [R] Rádio  [J] Livro  [F] Lanterna  [Esc] Pausa"


## Distance and direction to the current objective, relative to where the player is looking.
func _target_line() -> String:
	var target := GameState.objective_target()
	if target == Vector3.INF:
		return "\nRumo %s" % _heading()
	var to := target - player.global_position
	to.y = 0.0
	var forward := -player.global_transform.basis.z
	var bearing := rad_to_deg(atan2(to.x, -to.z)) - rad_to_deg(atan2(forward.x, -forward.z))
	var side: String = ["à frente", "à frente, direita", "à direita", "atrás, direita", "atrás", "atrás, esquerda", "à esquerda", "à frente, esquerda"][posmod(roundi(bearing / 45.0), 8)]
	return "\n%d m, %s · rumo %s" % [roundi(to.length()), side, _heading()]


## The hotbar: the first inventory row as small slots (icon + count), the selected one in brass,
## a pip on the drawn weapon. On touch screens a tap selects a slot.
class Hotbar extends Control:
	const SLOT := 18
	const GAP := 1
	const WIDTH := SLOT * 8 + GAP * 7

	var _icons := {}

	func _gui_input(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			var index := floori(click.position.x / (SLOT + GAP))
			if index >= 0 and index < GameState.INVENTORY.HOTBAR:
				GameState.select_hotbar(index)
			accept_event()

	func _draw() -> void:
		var inventory = GameState.inventory
		var font := get_theme_default_font()
		for i in GameState.INVENTORY.HOTBAR:
			var rect := Rect2(i * (SLOT + GAP), 0, SLOT, SLOT)
			var chosen: bool = i == inventory.selected
			draw_rect(rect, Color(UiKit.INK, 0.75))
			draw_rect(rect.grow(-1), Color(0.2, 0.26, 0.22, 0.8) if chosen else Color(0.1, 0.14, 0.12, 0.55))
			if not chosen:
				# slot number, faint, top-right (under the icon, so it never covers it)
				draw_string(font, rect.position + Vector2(SLOT - 7.0, 9.0), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, Color(UiKit.MUTED, 0.5))
			var stack: Dictionary = inventory.slots[i]
			if not stack.is_empty():
				if not _icons.has(stack.id):
					_icons[stack.id] = INVENTORY_PANEL.item_texture(stack.id)
				draw_texture(_icons[stack.id], rect.position + Vector2(1, 1), Color(1, 1, 1, 1.0 if chosen else 0.7))
				if stack.id == GameState.equipped:
					draw_rect(Rect2(rect.position + Vector2(2, 2), Vector2(3, 3)), UiKit.BRASS)
				if stack.count > 1:
					var text := str(stack.count)
					var at := rect.position + Vector2(SLOT - 2.0 - font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE).x, SLOT - 1.0)
					draw_string(font, at + Vector2.ONE, text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.INK)
					draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.FONT_SIZE, UiKit.CREAM)
			if chosen:
				draw_rect(rect, UiKit.BRASS, false, 1.0)
