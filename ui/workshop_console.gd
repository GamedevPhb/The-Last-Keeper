extends "res://ui/puzzle_console.gd"
## Console of the workshop (`puzzles/workshop.gd`): one button per recipe.

const W_ITEMS := preload("res://items/inventory.gd")
const W_PICKUP := preload("res://items/pickup.gd")

var workshop: Node

var _captions: Array[Label] = []
var _status: Label


func _build_body(body: VBoxContainer) -> void:
	_title.text = "OFICINA"
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in workshop.RECIPES.size():
		var recipe: Array = workshop.RECIPES[i]
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 56
		column.add_theme_constant_override("separation", 2)
		var top := CenterContainer.new()
		top.add_child(_icon_button(i, _swatch(recipe[0]), W_ITEMS.item_name(recipe[0])))
		column.add_child(top)
		var caption := UiKit.label("")
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(caption)
		_captions.append(caption)
		row.add_child(column)
	body.add_child(row)
	_status = UiKit.label("", 250)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(_status)


func _swatch(id: String) -> ImageTexture:
	var color: Color = W_PICKUP.COLORS.get(id, Color(0.6, 0.6, 0.6))
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(2, 14):
		for x in range(2, 14):
			var edge := x == 2 or y == 2 or x == 13 or y == 13
			img.set_pixel(x, y, Color(0.03, 0.05, 0.05) if edge else (color.lightened(0.25) if y < 5 else color))
	return ImageTexture.create_from_image(img)


func _action_count() -> int:
	return workshop.RECIPES.size()


func _on_press(index: int, _still_held: Callable) -> void:
	var recipe: Array = workshop.RECIPES[index]
	if workshop.craft(index):
		GameState.say("Você fabrica %d %s." % [recipe[1], W_ITEMS.item_name(recipe[0]).to_lower()])
	else:
		GameState.say("Faltam materiais: %s." % _cost_text(recipe))


func _cost_text(recipe: Array) -> String:
	var parts: Array[String] = []
	for id: String in recipe[2]:
		parts.append("%s x%d" % [W_ITEMS.item_name(id), recipe[2][id]])
	return ", ".join(parts)


func _refresh() -> void:
	_header.text = "RESTOS x%d  CARVÃO x%d" % [GameState.inventory.count("scrap"), GameState.inventory.count("coal")]
	for i in _captions.size():
		_captions[i].text = "%s x%d" % [W_ITEMS.item_name(workshop.RECIPES[i][0]), workshop.RECIPES[i][1]]
	_status.text = "Custo: " + _cost_text(workshop.RECIPES[clampi(_focus, 0, _captions.size() - 1)])
