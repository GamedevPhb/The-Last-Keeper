extends Marker3D
## Breaker panel: the generator only feeds POWER_CAPACITY circuits at once.

const CIRCUITS := {"radio": "Rádio", "house": "Luz da casa", "motor": "Motor da lanterna"}

var _switches := {}


func _ready() -> void:
	var x := -0.22
	for circuit in CIRCUITS:
		var item := Interactable.create("", 0.0, 0.11)
		item.name = "Breaker_%s" % circuit
		item.position = Vector3(x, 0.0, 0.1)
		x += 0.22
		add_child(item)
		item.interacted.connect(func(_by: Node) -> void: GameState.toggle_breaker(circuit))
		_switches[circuit] = item
	GameState.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	for circuit: String in _switches:
		var on: bool = GameState.breakers[circuit]
		_switches[circuit].prompt = "%s: %s" % [CIRCUITS[circuit], "ligado" if on else "desligado"]
