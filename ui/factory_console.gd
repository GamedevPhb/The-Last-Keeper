class_name FactoryConsole
extends "res://ui/puzzle_console.gd"
## Console of a converter station (`puzzles/factory.gd`): one button per accepted raw material
## (deposits one from the bag per press, hold to keep loading), a progress bar and COLETAR.

const FACTORY_ITEMS := preload("res://items/inventory.gd")
const FACTORY_PICKUP := preload("res://items/pickup.gd")
const HOLD_STEP := 0.25

var factory: Node

var _captions: Array[Label] = []
var _bar: Bar
var _status: Label
var _hint: Label
var _hold_left := 0.0


func _build_body(body: VBoxContainer) -> void:
	_title.text = "FÁBRICA"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var ids: PackedStringArray = factory.input_items
	for i in ids.size():
		row.add_child(_column(i, ids[i], _swatch(ids[i]), FACTORY_ITEMS.item_name(ids[i])))
	row.add_child(_column(ids.size(), "", _swatch(factory.output_item), "COLETAR"))
	body.add_child(row)
	_bar = Bar.new()
	_bar.custom_minimum_size = Vector2(150, 10)
	var bar_row := CenterContainer.new()
	bar_row.add_child(_bar)
	body.add_child(bar_row)
	_status = UiKit.label("", 250)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)
	_hint = UiKit.label("")
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_hint)


func _column(index: int, _id: String, texture: Texture2D, text: String) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 58
	column.add_theme_constant_override("separation", 2)
	var top := CenterContainer.new()
	top.add_child(_icon_button(index, texture, text))
	column.add_child(top)
	var caption := UiKit.label(text)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(caption)
	_captions.append(caption)
	return column


## A flat 16x16 swatch tinted like the item's pickup.
func _swatch(id: String) -> ImageTexture:
	var color: Color = FACTORY_PICKUP.COLORS.get(id, Color(0.6, 0.6, 0.6))
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(2, 14):
		for x in range(2, 14):
			var edge := x == 2 or y == 2 or x == 13 or y == 13
			img.set_pixel(x, y, Color(0.03, 0.05, 0.05) if edge else (color.lightened(0.25) if y < 5 else color))
	return ImageTexture.create_from_image(img)


func _on_press(index: int, still_held: Callable) -> void:
	var ids: PackedStringArray = factory.input_items
	if index >= ids.size():
		var amount: int = factory.collect()
		GameState.say("Você recolhe %d %s." % [amount, FACTORY_ITEMS.item_name(factory.output_item)] if amount > 0 else "Nada pronto ainda.")
		return
	_deposit(ids[index])
	_hold_left = HOLD_STEP
	_begin_hold(index, still_held)


func _hold_tick(delta: float) -> void:
	_hold_left -= delta
	if _hold_left > 0.0:
		return
	_hold_left = HOLD_STEP
	var ids: PackedStringArray = factory.input_items
	if _held >= 0 and _held < ids.size():
		_deposit(ids[_held])


func _deposit(id: String) -> void:
	if GameState.inventory.count(id) <= 0:
		GameState.say("Você não tem %s." % FACTORY_ITEMS.item_name(id).to_lower())
	elif factory.stock_room() <= 0:
		GameState.say("A máquina está cheia.")
	elif factory.deposit(id, 1) > 0:
		GameState.play("clunk", factory.global_position)


func _refresh() -> void:
	var ids: PackedStringArray = factory.input_items
	_title.text = factory.title.to_upper()
	for i in ids.size():
		_captions[i].text = "%s x%d" % [FACTORY_ITEMS.item_name(ids[i]), GameState.inventory.count(ids[i])]
	_captions[ids.size()].text = "COLETAR x%d" % factory.ready_units
	_header.text = "FUNCIONANDO" if factory.running() else ("PRONTO" if factory.ready_units > 0 else "PARADA")
	_bar.value = factory.progress_ratio()
	_bar.queue_redraw()
	_status.text = "Carga %d/%d · %d %s prontas · %d insumos por unidade" % [
		factory.stock, factory.stock + factory.stock_room(), factory.ready_units,
		FACTORY_ITEMS.item_name(factory.output_item).to_lower(), factory.inputs_per_unit]
	_hint.text = "[%d] %s" % [_focus + 1, "coletar" if _focus >= ids.size() else "depositar " + FACTORY_ITEMS.item_name(ids[_focus]).to_lower()]


## Progress of the unit being made.
class Bar extends Control:
	var value := 0.0

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), UiKit.INK)
		draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), Color(0.06, 0.1, 0.09))
		draw_rect(Rect2(1, 1, (size.x - 2) * value, size.y - 2), UiKit.BRASS)
