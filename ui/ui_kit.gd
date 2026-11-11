class_name UiKit
## Shared look for every menu: rusted brass and drowned-teal slabs, PS1-sized.
## `build_theme()` is baked into res://ui/theme.tres (project setting gui/theme/custom) by tests/make_theme.gd;
## the helpers below build common widgets.

const FONT_SIZE := 9
const HEADING_SIZE := 14

const BONE := Color(0.88, 0.84, 0.7)
const SEA := Color(0.62, 0.78, 0.68)
const BRASS := Color(0.78, 0.64, 0.34)
const RUST := Color(0.36, 0.2, 0.11)
const BLOOD := Color(0.72, 0.12, 0.09)
const INK := Color(0.03, 0.05, 0.05)

static var _cache := {}


static func build_theme() -> Theme:
	if _cache.has("theme"):
		return _cache["theme"]
	var font: Font = load("res://ui/fonts/DejaVuSerifCondensed-Bold.ttf")
	var t := Theme.new()
	t.default_font = font
	t.default_font_size = FONT_SIZE

	t.set_stylebox("panel", "PanelContainer", slab())
	t.set_stylebox("panel", "Panel", slab())

	t.set_color("font_color", "Label", BONE)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.9))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)

	for kind in ["Button", "CheckBox"]:
		t.set_color("font_color", kind, BONE)
		t.set_color("font_hover_color", kind, Color(1, 0.92, 0.66))
		t.set_color("font_focus_color", kind, Color(1, 0.92, 0.66))
		t.set_color("font_pressed_color", kind, Color(1, 0.7, 0.55) if kind == "Button" else BONE)
		t.set_color("font_hover_pressed_color", kind, Color(1, 0.8, 0.6))
		t.set_color("font_disabled_color", kind, Color(0.4, 0.42, 0.38))
	t.set_stylebox("normal", "Button", _plate(Color(0.08, 0.12, 0.11), Color(0.4, 0.5, 0.45), INK))
	t.set_stylebox("hover", "Button", _plate(Color(0.3, 0.06, 0.05), BRASS, Color(0.12, 0.02, 0.02)))
	t.set_stylebox("focus", "Button", _plate(Color(0.3, 0.06, 0.05), BRASS, Color(0.12, 0.02, 0.02)))
	t.set_stylebox("pressed", "Button", _plate(Color(0.16, 0.03, 0.03), Color(0.12, 0.02, 0.02), BRASS))
	t.set_stylebox("disabled", "Button", _plate(Color(0.05, 0.07, 0.07), Color(0.2, 0.24, 0.22), INK))

	t.set_constant("h_separation", "CheckBox", 4)
	t.set_icon("unchecked", "CheckBox", _box_icon(false))
	t.set_icon("checked", "CheckBox", _box_icon(true))
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", _plate(Color(0.3, 0.06, 0.05, 0.5), BRASS, Color(0.12, 0.02, 0.02)))

	var groove := _flat(Color(0.02, 0.03, 0.03), RUST)
	groove.content_margin_top = 2
	groove.content_margin_bottom = 2
	t.set_stylebox("slider", "HSlider", groove)
	t.set_stylebox("grabber_area", "HSlider", _flat(Color(0.5, 0.09, 0.07), Color(0.5, 0.09, 0.07)))
	t.set_stylebox("grabber_area_highlight", "HSlider", _flat(Color(0.72, 0.14, 0.1), Color(0.72, 0.14, 0.1)))
	t.set_icon("grabber", "HSlider", _bolt(false))
	t.set_icon("grabber_highlight", "HSlider", _bolt(true))
	t.set_icon("grabber_disabled", "HSlider", _bolt(false))

	var rule := StyleBoxLine.new()
	rule.color = RUST
	rule.thickness = 1
	t.set_stylebox("separator", "HSeparator", rule)
	t.set_constant("separation", "HSeparator", 5)
	_cache["theme"] = t
	return t


## Big bevelled frame with rivets in the corners, used for every panel.
static func slab() -> StyleBoxTexture:
	return _nine("slab", 20, 7, Color(0.045, 0.075, 0.07, 0.96), BRASS, RUST, true, 9)


## Thin version of the slab for HUD strips.
static func bar() -> StyleBoxTexture:
	return _plate(Color(0.04, 0.07, 0.07, 0.9), Color(0.5, 0.4, 0.22), INK)


static func _plate(face: Color, hi: Color, lo: Color) -> StyleBoxTexture:
	var key := "plate%s%s%s" % [face, hi, lo]
	var box := _nine(key, 12, 3, face, hi, lo, false, 3)
	box.content_margin_top = 3
	box.content_margin_bottom = 3
	return box


static func _nine(key: String, size: int, margin: int, face: Color, hi: Color, lo: Color, rivets: bool, content: int) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	if not _cache.has(key):
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		for y in size:
			for x in size:
				var c := face
				if (x + y) % 2 == 0:
					c = face.darkened(0.18)
				if x == 0 or y == 0 or x == size - 1 or y == size - 1:
					c = INK
				elif x == 1 or y == 1:
					c = hi
				elif x == size - 2 or y == size - 2:
					c = lo
				elif rivets and (x == 2 or y == 2 or x == size - 3 or y == size - 3):
					c = lo.darkened(0.45)
				img.set_pixel(x, y, c)
		if rivets:
			for corner: Vector2i in [Vector2i(3, 3), Vector2i(size - 5, 3), Vector2i(3, size - 5), Vector2i(size - 5, size - 5)]:
				img.set_pixel(corner.x, corner.y, hi.lightened(0.2))
				img.set_pixel(corner.x + 1, corner.y, hi)
				img.set_pixel(corner.x, corner.y + 1, hi)
				img.set_pixel(corner.x + 1, corner.y + 1, lo.darkened(0.5))
		_cache[key] = ImageTexture.create_from_image(img)
	box.texture = _cache[key]
	box.set_texture_margin_all(margin)
	box.set_content_margin_all(content)
	return box


static func _flat(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(1)
	return box


static func _box_icon(checked: bool) -> ImageTexture:
	var key := "box%s" % checked
	if not _cache.has(key):
		var img := Image.create(9, 9, false, Image.FORMAT_RGBA8)
		img.fill(INK)
		for i in range(1, 8):
			for j in range(1, 8):
				img.set_pixel(i, j, Color(0.07, 0.1, 0.09))
		for i in 9:
			img.set_pixel(i, 0, RUST)
			img.set_pixel(0, i, RUST)
		if checked:
			for i in range(2, 7):
				img.set_pixel(i, i, BLOOD)
				img.set_pixel(8 - i, i, BLOOD)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func _bolt(lit: bool) -> ImageTexture:
	var key := "bolt%s" % lit
	if not _cache.has(key):
		var img := Image.create(5, 9, false, Image.FORMAT_RGBA8)
		img.fill(INK)
		for y in range(1, 8):
			for x in range(1, 4):
				img.set_pixel(x, y, BRASS if lit else Color(0.5, 0.42, 0.24))
		for y in range(1, 8):
			img.set_pixel(3, y, RUST)
		_cache[key] = ImageTexture.create_from_image(img)
	return _cache[key]


static func style(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_content_margin_all(6)
	return box


static func label(text: String, width := 0, color := BONE) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", FONT_SIZE)
	item.add_theme_color_override("font_color", color)
	if color.get_luminance() < 0.3:
		item.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	if width > 0:
		item.custom_minimum_size.x = width
		item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return item


static func heading(text: String) -> Label:
	var item := label(text, 0, BRASS)
	item.add_theme_font_size_override("font_size", HEADING_SIZE)
	item.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return item


static func button(text: String, action: Callable) -> Button:
	var item := Button.new()
	item.text = text
	item.add_theme_font_size_override("font_size", FONT_SIZE)
	item.pressed.connect(action)
	return item


static func panel() -> PanelContainer:
	return PanelContainer.new()
