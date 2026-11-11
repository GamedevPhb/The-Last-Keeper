class_name UiKit
## Small helpers so every menu shares the same PS1-sized look.

const FONT_SIZE := 8


static func style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(6)
	return box


static func label(text: String, width := 0, color := Color(0.92, 0.9, 0.82)) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", FONT_SIZE)
	item.add_theme_color_override("font_color", color)
	if width > 0:
		item.custom_minimum_size.x = width
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item


static func button(text: String, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.add_theme_font_size_override("font_size", FONT_SIZE)
	item.pressed.connect(action)
	return item


static func panel() -> PanelContainer:
	var item := PanelContainer.new()
	item.add_theme_stylebox_override("panel", style(Color(0.05, 0.06, 0.08, 0.94), Color(0.45, 0.38, 0.26)))
	return item
