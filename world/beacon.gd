class_name Beacon
extends Node3D
## The lighthouse lamp. A cold start needs three steps in order (oil, spring, lens);
## once lit it burns oil, unwinds and gets dirty until the keeper tends it again.

@export var rotation_speed := 0.6 ## radians per second at full spring
@export var oil_burn := 1.0 / 240.0 ## per second
@export var spring_unwind := 1.0 / 150.0 ## per second, unless the motor circuit is powered
@export var dirt_rate := 1.0 / 360.0 ## per second

const STEPS := ["óleo", "corda", "lente"]

var lit := false:
	set(value):
		lit = value
		GameState.lamp_lit = value
		if is_node_ready():
			_apply()
var oil := 0.0
var wound := 0.0
var dirt := 0.6

var _step := 0
var _oil_tank: Interactable
var _crank: Interactable
var _lens: Interactable

@onready var _head: Node3D = $Head
@onready var _bulb: MeshInstance3D = $Bulb
@onready var _glow: OmniLight3D = $Glow
@onready var _spot: SpotLight3D = $Head/Spot
@onready var _switch: Interactable = $Interactable


func _ready() -> void:
	_oil_tank = _add_station("OilTank", Vector3(0.95, -0.3, 0.0), 0.0)
	_crank = _add_station("Crank", Vector3(-0.95, -0.3, 0.0), 1.5)
	_lens = _add_station("Lens", Vector3(0.0, 0.1, 0.95), 1.5)
	_oil_tank.interacted.connect(_on_oil)
	_crank.interacted.connect(_on_crank)
	_lens.interacted.connect(_on_lens)
	_apply()


func _process(delta: float) -> void:
	_update_prompts()
	if not lit:
		return
	oil -= oil_burn * (1.0 + GameState.progress()) * delta
	wound = 1.0 if GameState.powered("motor") else wound - spring_unwind * delta
	dirt = minf(dirt + dirt_rate * delta, 1.0)
	_head.rotate_y(rotation_speed * delta * clampf(wound * 2.0, 0.2, 1.0))
	_spot.light_energy = 6.0 * (1.0 - 0.7 * dirt)
	if oil <= 0.0:
		_go_out("sem óleo")
	elif wound <= 0.0:
		_go_out("a corda acabou")


func _add_station(node_name: String, pos: Vector3, hold: float) -> Interactable:
	var item := Interactable.create("", hold, 0.35)
	item.name = node_name
	item.position = pos
	add_child(item)
	return item


func _update_prompts() -> void:
	if lit:
		_switch.prompt = "Apagar a lâmpada"
	elif _step >= STEPS.size():
		_switch.prompt = "Acender a lâmpada"
	else:
		_switch.prompt = "Lâmpada: falta %s" % STEPS[_step]
	_oil_tank.prompt = "Abastecer óleo (%d%%)" % roundi(oil * 100.0)
	_crank.prompt = "Dar corda (%d%%)" % roundi(wound * 100.0)
	_lens.prompt = "Limpar a lente (%d%% suja)" % roundi(dirt * 100.0)


## While cold the three tasks must be done in order; wrong order jams the mechanism.
func _can_do(step: int) -> bool:
	if lit or step == _step:
		return true
	_step = 0
	GameState.play("jam", global_position)
	GameState.say("O mecanismo emperra. Recomece pelo óleo.")
	return false


func _advance(step: int) -> void:
	if not lit:
		_step = step + 1


func _on_oil(_by: Node) -> void:
	if not _can_do(0):
		return
	if GameState.oil_cans < 1:
		GameState.say("Sem óleo. O tambor está no ilhéu, e só dá para chegar na maré baixa.")
		return
	GameState.oil_cans -= 1
	oil = 1.0
	GameState.play("clunk", global_position)
	_advance(0)


func _on_crank(_by: Node) -> void:
	if not _can_do(1):
		return
	wound = 1.0
	GameState.play("creak", global_position)
	_advance(1)


func _on_lens(_by: Node) -> void:
	if not _can_do(2):
		return
	dirt = 0.0
	GameState.play("paper", global_position)
	_advance(2)


func _on_interacted(_by: Node) -> void:
	if lit:
		lit = false
		_step = 0
	elif _step < STEPS.size():
		GameState.say("A lâmpada ainda não está pronta: falta %s." % STEPS[_step])
	else:
		lit = true
		GameState.lamp_lit_once = true
		GameState.play("ignite", global_position)


func _go_out(reason: String) -> void:
	lit = false
	_step = 0
	GameState.say("A lâmpada apagou: %s." % reason)


func _apply() -> void:
	_head.visible = lit
	_bulb.visible = lit
	_glow.visible = lit
