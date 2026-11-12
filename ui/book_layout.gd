extends RefCounted
## Logbook page standard: every page is one sheet of the same size (PAGE_SIZE) with a fixed
## layout: title line, stamp line (date/time or place), a rule, the body (at most BODY_LINES
## lines, left aligned) and the page number centered at the foot. All the numbers live here.
## `paginate()` word-wraps an entry to the body width and splits it into as many sheets as it
## needs, so long texts add pages instead of stretching one. Used by `ui/overlay.gd`; the sheet node is `ui/book_page.gd`.

const PAGE_SIZE := Vector2(132, 152)
const MARGIN := 6.0 ## left, right, top and bottom
const FONT_SIZE := 9 ## title, stamp, body and number share one size (PS1 pixel font)
const LINE_GAP := 1.0 ## extra pixels between body lines
const HEADER_LINES := 2 ## title + stamp
const FOOTER_HEIGHT := 12.0
const RULE_GAP := 3.0
const NUMBER_FORMAT := "- %d -"
const CONTINUED := " (cont.)"
const DEFAULT_STAMP := "Farol 7 · Noite 1"
const PAPER := Color(0.76, 0.7, 0.55)
const PAPER_EDGE := Color(0.4, 0.32, 0.2)
const INK := Color(0.14, 0.09, 0.04)
const INK_TITLE := Color(0.33, 0.14, 0.07)
const INK_FAINT := Color(0.38, 0.3, 0.2)


static func text_width() -> float:
	return PAGE_SIZE.x - MARGIN * 2.0


static func line_height(font: Font) -> float:
	return font.get_height(FONT_SIZE) + LINE_GAP


static func header_height(font: Font) -> float:
	return font.get_height(FONT_SIZE) * HEADER_LINES + RULE_GAP * 2.0


static func body_top(font: Font) -> float:
	return MARGIN + header_height(font)


static func body_height(font: Font) -> float:
	return PAGE_SIZE.y - MARGIN - FOOTER_HEIGHT - body_top(font)


static func max_lines(font: Font) -> int:
	return maxi(floori(body_height(font) / line_height(font)), 1)


## Word-wraps `text` to the body width; blank lines in the text are kept as blank lines.
static func wrap_text(text: String, font: Font) -> Array[String]:
	var lines: Array[String] = []
	var width := text_width()
	for paragraph in text.split("\n"):
		if paragraph.strip_edges().is_empty():
			lines.append("")
			continue
		var line := ""
		for word in paragraph.split(" ", false):
			var candidate := word if line.is_empty() else line + " " + word
			if line.is_empty() or font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x <= width:
				line = candidate
			else:
				lines.append(line)
				line = word
		lines.append(line)
	return lines


## Entries are {title, body, stamp (optional)}. Returns the sheets, numbered from 1:
## {title, stamp, body (text of at most max_lines lines), number}.
static func paginate(entries: Array, font: Font) -> Array[Dictionary]:
	var sheets: Array[Dictionary] = []
	var limit := max_lines(font)
	for entry: Dictionary in entries:
		var lines := wrap_text(entry.body, font)
		while not lines.is_empty() and lines[0] == "":
			lines.pop_front()
		var first := true
		while first or not lines.is_empty():
			var chunk: Array = lines.slice(0, limit)
			lines = lines.slice(limit)
			# A blank line at the cut is wasted space; a lone blank leading the next sheet too.
			while not chunk.is_empty() and chunk[-1] == "":
				chunk.pop_back()
			while not lines.is_empty() and lines[0] == "":
				lines.pop_front()
			sheets.append({
				"title": entry.title if first else entry.title + CONTINUED,
				"stamp": entry.get("stamp", DEFAULT_STAMP),
				"body": "\n".join(chunk),
				"number": sheets.size() + 1,
			})
			first = false
	return sheets
