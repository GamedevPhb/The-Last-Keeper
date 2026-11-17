extends SceneTree
## Headless test of the flashlight battery and the lens cleaner: drain while on, battery and
## lens items from the inventory, dead battery turns the beam off, save round trip.
## Run: godot-4 --headless --path . --script res://tests/flashlight_test.gd

var _failures := 0
var _frame := 0


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	var state := root.get_node("GameState")
	var overlay: Node = root.get_node("Main/Overlay") if root.has_node("Main/Overlay") else null
	state.in_game = true
	state.has_flashlight = true
	var inv = state.inventory

	_check(state.flashlight_battery == 100.0, "battery starts full")
	state.flashlight_on = true
	state._tick_flashlight(30.0)
	_check(state.flashlight_battery < 100.0 and state.flashlight_battery > 70.0, "battery drains while on")
	state.flashlight_on = false
	var idle: float = state.flashlight_battery
	state._tick_flashlight(30.0)
	_check(state.flashlight_battery == idle, "no drain while off")

	inv.add("battery", 2)
	_check(state.use_battery() and state.flashlight_battery > idle and inv.count("battery") == 1, "battery recharges and is consumed")
	state.flashlight_battery = 100.0
	_check(not state.use_battery() and inv.count("battery") == 1, "full flashlight keeps the battery")

	_check(not state.use_lens_cleaner(), "no cleaner in the inventory: nothing happens")
	inv.add("lens_cleaner", 1)
	_check(state.use_lens_cleaner() and state.lens_left > 0.0 and inv.count("lens_cleaner") == 0, "cleaner boosts and is consumed")

	var saved: Dictionary = state.to_save()
	state.lens_left = 0.0
	state.flashlight_battery = 5.0
	state.from_save(saved)
	_check(state.lens_left > 0.0 and state.flashlight_battery == 100.0, "battery and lens survive a save")

	state.flashlight_on = true
	state.flashlight_battery = 0.5
	state._tick_flashlight(5.0)
	_check(state.flashlight_battery == 0.0 and state.lens_left == 0.0, "dead battery ends the lens boost")

	for item in ["battery", "lens_cleaner"]:
		_check(state.INVENTORY.ITEMS.has(item), "%s is an item" % item)
	var chest: Node = root.get_node("Main").find_child("Chest", true, false)
	_check(chest != null, "chest exists")
	# Logbook: long text splits into same-size sheets (never more than max_lines lines).
	var layout := load("res://ui/book_layout.gd")
	var font: Font = ThemeDB.get_project_theme().get_font("font", "Label")
	var long := ""
	for i in 80:
		long += "palavra%d " % i
	var sheets: Array = layout.paginate([{"title": "T", "body": long}, {"title": "U", "body": "curto"}], font)
	print("book sheets: ", sheets.size(), " max lines ", layout.max_lines(font))
	_check(sheets.size() >= 3, "long text paginates into several sheets")
	for sheet: Dictionary in sheets:
		_check(sheet.body.count("\n") + 1 <= layout.max_lines(font), "sheet %d fits" % sheet.number)
	_check(sheets[1].title == "T" + layout.CONTINUED and sheets[-1].number == sheets.size(), "continuation title and numbering")
	if _failures > 0:
		printerr("FLASHLIGHT TEST FAILED: %d checks" % _failures)
		quit(1)
	else:
		print("FLASHLIGHT TEST PASSED")
		quit(0)
	return true


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)
