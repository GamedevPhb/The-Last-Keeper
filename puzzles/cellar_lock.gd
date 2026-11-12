extends Marker3D
## Three-dial padlock on the cellar hatch. The digits are written on things around the island.

const CODE := [8, 3, 5]

var _digits := [0, 0, 0]
var _dials: Array[Interactable] = []
var _open := false


func _ready() -> void:
	for i in CODE.size():
		var dial := Interactable.create("", 0.0, 0.18)
		dial.name = "Dial%d" % i
		dial.position = Vector3(-0.45 + 0.45 * i, 0.0, 0.0)
		add_child(dial)
		dial.interacted.connect(_on_dial.bind(i))
		_dials.append(dial)
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
		for dial in _dials:
			dial.enabled = false


func _on_dial(_by: Node, index: int) -> void:
	GameState.add_note("Porão da casa: cadeado de 3 discos. Os números estão escritos pela ilha.")
	_digits[index] = (_digits[index] + 1) % 10
	GameState.play("click", global_position)
	_refresh()
	if _digits == CODE:
		_unlock()


func _refresh() -> void:
	for i in _dials.size():
		_dials[i].prompt = "Cadeado %d/3: %d" % [i + 1, _digits[i]]


func _unlock() -> void:
	if _open:
		return
	_open = true
	var hatch := get_node_or_null("../../Props/CellarHatch")
	if hatch:
		hatch.queue_free()
	for dial in _dials:
		dial.enabled = false
	GameState.play("bell", global_position)
	# The pantry: lamp reserves plus the food that rewards cracking the code (GDD 4.10).
	var at := global_position + Vector3(0.0, 0.1, 0.6)
	for entry: Array in [["oil", 2], ["fuel", 1], ["can", 3], ["water", 2], ["bandage", 1]]:
		GameState.give(entry[0], entry[1], at)
	GameState.say("O porão guardava reservas: 2 latas de óleo, 1 de combustível, 3 conservas, 2 garrafas d'água e 1 curativo.")
