extends Marker3D
## The oil drum on the islet. Only a few cans are left in it.

var cans := 3

var _pickup: Interactable


func _ready() -> void:
	_pickup = Interactable.create("Pegar uma lata de óleo", 1.0, 0.6)
	_pickup.name = "Pickup"
	add_child(_pickup)
	_pickup.interacted.connect(_on_pickup)


func _on_pickup(_by: Node) -> void:
	cans -= 1
	GameState.oil_cans += 1
	if cans <= 0:
		_pickup.enabled = false
		GameState.say("Você pega a última lata do tambor.")
	else:
		GameState.say("Você pega uma lata de óleo. Restam %d no tambor." % cans)
