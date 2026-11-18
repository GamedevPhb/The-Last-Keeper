extends Panel
## One fixed-size logbook sheet (`ui/book_layout.gd` holds the standard). The size never
## depends on the text: labels are clipped, not wrapped.

const LAYOUT := preload("res://ui/book_layout.gd")

var _title: Label
var _stamp: Label
var _body: Label
var _number: Label
var _rule: ColorRect


func _init() -> void:
	custom_minimum_size = LAYOUT.PAGE_SIZE
	size = LAYOUT.PAGE_SIZE
	clip_contents = true
	add_theme_stylebox_override("panel", UiKit.style(LAYOUT.PAPER, LAYOUT.PAPER_EDGE))
	_title = _line(LAYOUT.INK_TITLE)
	_stamp = _line(LAYOUT.INK_FAINT)
	_body = _line(LAYOUT.INK)
	_number = _line(LAYOUT.INK_FAINT)
	_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_theme_constant_override("line_spacing", int(LAYOUT.LINE_GAP))
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_rule = ColorRect.new()
	_rule.color = LAYOUT.INK_FAINT
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rule)


func _ready() -> void:
	var font := get_theme_font("font", "Label")
	var text_h := font.get_height(LAYOUT.FONT_SIZE)
	_title.position = Vector2(LAYOUT.MARGIN, LAYOUT.MARGIN)
	_title.size = Vector2(LAYOUT.text_width(), text_h)
	_stamp.position = Vector2(LAYOUT.MARGIN, LAYOUT.MARGIN + text_h)
	_stamp.size = Vector2(LAYOUT.text_width(), text_h)
	_rule.position = Vector2(LAYOUT.MARGIN, LAYOUT.MARGIN + text_h * LAYOUT.HEADER_LINES + LAYOUT.RULE_GAP)
	_rule.size = Vector2(LAYOUT.text_width(), 1.0)
	_body.position = Vector2(LAYOUT.MARGIN, LAYOUT.body_top(font))
	_body.size = Vector2(LAYOUT.text_width(), LAYOUT.body_height(font))
	_number.position = Vector2(LAYOUT.MARGIN, LAYOUT.PAGE_SIZE.y - LAYOUT.MARGIN - text_h)
	_number.size = Vector2(LAYOUT.text_width(), text_h)


func show_sheet(sheet: Dictionary) -> void:
	_title.text = sheet.title
	_stamp.text = sheet.stamp
	_body.text = sheet.body
	_number.text = LAYOUT.NUMBER_FORMAT % sheet.number if sheet.number > 0 else ""


func _line(color: Color) -> Label:
	var item := UiKit.label("", 0, color)
	item.add_theme_font_size_override("font_size", LAYOUT.FONT_SIZE)
	item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0)) # ink on paper: a shadow only smears it
	item.clip_text = true
	item.autowrap_mode = TextServer.AUTOWRAP_OFF
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item)
	return item
