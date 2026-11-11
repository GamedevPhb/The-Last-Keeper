extends Marker3D
## Generator in the shed. The four valves must be opened in the order the logbook gives,
## then the tank keeps it alive until the fuel runs out.

const LABELS := ["A", "B", "C", "D"]
const FUEL_BURN := 1.0 / 300.0 ## per second
const BARRELS := [Vector3(-23.3, 0.9, 13.4), Vector3(-23.3, 0.9, 14.6), Vector3(-23.3, 0.9, 15.8)]

var order: Array = [0, 1, 2, 3]
var fuel := 0.0
var running := false

var _progress := 0
var _valves: Array[Interactable] = []
var _lights: Array[StandardMaterial3D] = []
var _tank: Interactable


func _ready() -> void:
	add_to_group("generator")
	order.shuffle()
	for i in LABELS.size():
		_valves.append(_add_valve(i))
	_tank = _add("FuelIn", Vector3(0.4, -0.3, 0.0), "", 1.5, 0.3)
	_tank.interacted.connect(_on_refuel)
	for i in BARRELS.size():
		var barrel := _add("Barrel%d" % i, Vector3.ZERO, "Pegar combustível", 1.0, 0.45)
		barrel.global_position = BARRELS[i]
		barrel.interacted.connect(_on_barrel.bind(barrel))


func _process(delta: float) -> void:
	_tank.prompt = "Abastecer o gerador (%d%%)" % roundi(fuel * 100.0)
	if running:
		fuel -= FUEL_BURN * (1.0 + 0.5 * GameState.progress()) * delta
		if fuel <= 0.0:
			fuel = 0.0
			_stop("acabou o combustível")


func valve_order_text() -> String:
	return ", ".join(order.map(func(i: int) -> String: return LABELS[i]))


func _add(node_name: String, pos: Vector3, prompt_text: String, hold: float, radius: float) -> Interactable:
	var item := Interactable.create(prompt_text, hold, radius)
	item.name = node_name
	item.position = pos
	add_child(item)
	return item


func _add_valve(index: int) -> Interactable:
	var valve := _add("Valve%s" % LABELS[index], Vector3(-0.85, 0.7, -0.9 + 0.6 * index), "Válvula %s" % LABELS[index], 0.0, 0.22)
	var wheel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.09
	cylinder.bottom_radius = 0.09
	cylinder.height = 0.12
	cylinder.radial_segments = 8
	wheel.mesh = cylinder
	wheel.rotation_degrees = Vector3(0, 0, 90)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.15, 0.1)
	wheel.material_override = mat
	valve.add_child(wheel)
	_lights.append(mat)
	var label := Label3D.new()
	label.text = LABELS[index]
	label.pixel_size = 0.004
	label.font_size = 48
	label.position = Vector3(0.12, 0.2, 0.0)
	label.rotation_degrees = Vector3(0, 90, 0)
	label.modulate = Color(1, 0.9, 0.6)
	valve.add_child(label)
	valve.interacted.connect(_on_valve.bind(index))
	return valve


func _on_valve(_by: Node, index: int) -> void:
	if running:
		GameState.say("O gerador já está funcionando.")
	elif index == order[_progress]:
		_lights[index].albedo_color = Color(0.2, 0.6, 0.2)
		GameState.play("switch", global_position)
		_progress += 1
		if _progress == order.size():
			_start()
	else:
		GameState.play("jam", global_position)
		GameState.say("A pressão cai. Recomece as válvulas.")
		_reset()


func _start() -> void:
	if fuel <= 0.0:
		GameState.say("As válvulas abrem, mas o tanque está vazio. Há barris atrás do galpão.")
		_reset()
		return
	running = true
	GameState.generator_started = true
	GameState.generator_on = true
	GameState.play("gen_start", global_position)
	GameState.say("O gerador ronca e pega.")


func _stop(reason: String) -> void:
	running = false
	GameState.generator_on = false
	GameState.say("O gerador parou: %s." % reason)
	_reset()


func _reset() -> void:
	_progress = 0
	for mat in _lights:
		mat.albedo_color = Color(0.6, 0.15, 0.1)


func _on_refuel(_by: Node) -> void:
	if GameState.fuel_cans < 1:
		GameState.say("Sem lata de combustível. Os barris ficam atrás do galpão.")
		return
	GameState.fuel_cans -= 1
	fuel = 1.0
	GameState.play("clunk", global_position)


func _on_barrel(_by: Node, barrel: Interactable) -> void:
	barrel.enabled = false
	GameState.fuel_cans += 1
	GameState.play("clunk", barrel.global_position)
	GameState.say("Você enche uma lata de combustível.")
