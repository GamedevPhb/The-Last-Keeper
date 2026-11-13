extends Marker3D
## A gatherable spot (tree, seaweed, carcass, coal seam): hold E to collect `amount` of item
## `kind`, then it is spent until the next night (`cooldown_per_night` nights, 1 = every night).
## Level design just instances a Marker3D with this script and sets the exports:
## `kind` (an item id of `items/inventory.gd`), `amount`, `cooldown_per_night`, `prompt`.
## Spent state is tied to `GameState.night`, so it re-arms by itself on a later night.

@export var kind := "wood"
@export var amount := 2
@export var cooldown_per_night := 1 ## nights to wait after being gathered
@export var prompt := "" ## defaults to "Coletar <item>"
@export var hold_time := 1.2

const BASIC := ["wood", "algae", "fat"] ## gatherable from night 1 ("gather_basic"); the rest needs "gather"

var spent_night := -999 ## the night it was last gathered
var _switch: Interactable


func _ready() -> void:
	var label := prompt if not prompt.is_empty() else "Coletar " + Inventory.item_name(kind).to_lower()
	_switch = Interactable.create(label, hold_time, 0.6)
	_switch.name = "Gather"
	add_child(_switch)
	_switch.interacted.connect(_on_gathered)
	_apply()
	add_to_group("saveable")


func unlock_id() -> String:
	return "gather_basic" if kind in BASIC else "gather"


## Hidden and inert until its `UNLOCKS` night arrives.
func _process(_delta: float) -> void:
	if GameState.unlocked(unlock_id()) != visible:
		_apply()


func _on_gathered(_by: Node) -> void:
	if is_spent() or not GameState.unlocked(unlock_id()):
		return
	var taken: int = GameState.give(kind, amount, global_position + Vector3(0.0, 0.5, 0.0))
	GameState.play("clunk", global_position)
	spent_night = GameState.night
	_apply()
	GameState.say("Você coleta %d %s." % [amount, Inventory.item_name(kind).to_lower()] if taken > 0 else "Sem espaço: %s ficou no chão." % Inventory.item_name(kind).to_lower())


func is_spent() -> bool:
	return GameState.night < spent_night + maxi(cooldown_per_night, 1)


func _apply() -> void:
	var open := GameState.unlocked(unlock_id())
	visible = open
	_switch.enabled = open and not is_spent()


func save_state() -> Dictionary:
	return {"spent_night": spent_night}


func load_state(data: Dictionary) -> void:
	spent_night = int(data.get("spent_night", -999))
	_apply()
