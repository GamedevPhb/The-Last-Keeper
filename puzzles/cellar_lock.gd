extends Marker3D
## Three-dial padlock on the cellar hatch. The digits are written on things around the island.
## One Interactable opens the brass console (`ui/lock_console.gd`), which turns the dials.

## Preloaded instead of the class_name, so this compiles before the global class cache is rebuilt.
const LOCK_CONSOLE := preload("res://ui/lock_console.gd")
const CODE := [8, 3, 5]

var _digits := [0, 0, 0]
var _lock: Interactable
var _console: Node
var _open := false


func _ready() -> void:
	_lock = Interactable.create("Cadeado do porão", 0.0, 0.5)
	_lock.name = "Lock"
	add_child(_lock)
	_lock.interacted.connect(_on_interacted)
	_refresh()
	add_to_group("saveable")


func save_state() -> Dictionary:
	return {"open": _open, "digits": _digits}


func load_state(data: Dictionary) -> void:
	_digits = data.get("digits", _digits).map(func(d: float) -> int: return int(d))
	_refresh()
	if data.get("open", false) and not _open:
		_open = true
		var hatch := get_node_or_null("../../Props/CellarHatch")
		if hatch:
			hatch.queue_free()
		_lock.enabled = false


func digits() -> Array:
	return _digits.duplicate()


## Called by the console as the dials turn, so the padlock keeps its position (and the save).
func set_digits(value: Array) -> void:
	_digits = value.duplicate()
	_refresh()


func _on_interacted(by: Node) -> void:
	GameState.add_note("Porão da casa: cadeado de 3 discos. Os números estão escritos pela ilha.")
	if _console == null:
		_console = LOCK_CONSOLE.new()
		_console.lock = self
		add_child(_console)
	_console.open(by as Player)


func _refresh() -> void:
	_lock.prompt = "Cadeado do porão (%d-%d-%d)" % [_digits[0], _digits[1], _digits[2]]


## True when `value` is the code (and opens the hatch); the console calls this on CONFIRMAR.
func try_code(value: Array) -> bool:
	if value != CODE:
		return false
	unlock()
	return true


func unlock() -> void:
	if _open:
		return
	_open = true
	_digits = CODE.duplicate()
	_refresh()
	var hatch := get_node_or_null("../../Props/CellarHatch")
	if hatch:
		hatch.queue_free()
	_lock.enabled = false
	GameState.play("bell", global_position)
	# The pantry: lamp reserves plus the food that rewards cracking the code (GDD 4.10).
	var at := global_position + Vector3(0.0, 0.1, 0.6)
	for entry: Array in [["oil", 2], ["fuel", 1], ["can", 3], ["water", 2], ["bandage", 1], ["battery", 2], ["lens_cleaner", 1], ["shotgun", 1], ["shells", 4]]:
		GameState.give(entry[0], entry[1], at)
	GameState.say("O porão guardava reservas: 2 de óleo, 1 de combustível, 3 conservas, 2 águas, 1 curativo, 2 pilhas, 1 limpador de lente e a espingarda do vigia 9 com 4 cartuchos.")
