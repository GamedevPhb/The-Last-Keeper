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
	GameState.oil_cans += 2
	GameState.fuel_cans += 1
	GameState.say("O porão guardava reservas: 2 latas de óleo e 1 de combustível.")
