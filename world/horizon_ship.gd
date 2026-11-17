extends Node3D
## The ship anchored at the horizon (easter egg): the boatman sails to it at the start of the
## night and back at dawn. Separate from the radio ships. Its lamps come on at dusk and burn
## until the end of the night, drawn unshaded and fog-free so they read as points far away.

const SEA := -1.2
const POS := Vector3(-30.0, SEA, 108.0)
const SIDE := Vector3(-30.0, SEA, 101.5) ## where the boat reaches the hull, island side
const SCALE := 0.5
const LAMPS_ON := 18.5 * 60.0
const LAMPS_FULL := 19.5 * 60.0

var _lamps: Array[MeshInstance3D] = []
var _time := 0.0
var _answer := 0.0


func _ready() -> void:
	add_to_group("horizon_ship")
	var ship := Actors.cargo(Color(0.35, 0.38, 0.42), 0.6, SCALE)
	ship.position = POS
	ship.rotation.y = PI / 2.0
	add_child(ship)
	var model := ship.get_node("Hull").get_child(0) as Node3D
	var box: AABB = ship.get_meta("hull_box")
	var white := _lamp_material(Color(1.0, 0.97, 0.9))
	var amber := _lamp_material(Color(1.0, 0.7, 0.3))
	for x: float in [-35.8, -3.6, 34.4]:
		_lamp(model, Vector3(x, 31.0, 0.0), white)
	for i in 9:
		for z: float in [-box.size.z * 0.5, box.size.z * 0.5]:
			_lamp(model, Vector3(-40.0 + i * 10.0, box.position.y + box.size.y * (0.62 + 0.05 * (i % 2)), z), amber)
	_sync()


func _process(delta: float) -> void:
	_time += delta
	_answer = maxf(_answer - delta, 0.0)
	_sync()


## The ship answers the lighthouse (story scene "lamp"): every lamp blinks together for `seconds`.
func answer(seconds := 6.0) -> void:
	_answer = seconds


## Lamps on from 18:30 (all by 19:30); a few flicker, one goes dark at times.
func _sync() -> void:
	if _answer > 0.0:
		for lamp in _lamps:
			lamp.visible = fmod(_answer, 1.0) > 0.45
		return
	var level := smoothstep(LAMPS_ON, LAMPS_FULL, GameState.minutes)
	for i in _lamps.size():
		var lit := float(i) / _lamps.size() < level
		if i % 7 == 3:
			lit = lit and sin(_time * 0.7 + i) > -0.6
		_lamps[i].visible = lit


func _lamp(parent: Node3D, at: Vector3, mat: Material) -> void:
	var lamp := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 1.6
	lamp.mesh = mesh
	lamp.material_override = mat
	lamp.position = at
	parent.add_child(lamp)
	_lamps.append(lamp)


func _lamp_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.disable_fog = true
	return mat
