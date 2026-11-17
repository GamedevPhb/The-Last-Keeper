extends Node3D
## Easter egg: the giant Portinho (mascot of Porto Indie) waving from the NE horizon on night 1.
## Low-poly model (portinho_model.gd) at 22x, unshaded and fog-free, tinted as a dark blue-grey silhouette; it warms up for ~1 s each time the
## sweeping beam covers it. Three sweeps solve the puzzle (GameState.portinho_sweep). Hooks for the
## story scenes: `set_mood("wave" | "happy" | "thumbs_up")` and `point()`.

const MODEL := preload("res://world/portinho_model.gd")
const SCALE := 22.0 ## 1.8 m model -> ~40 m
const BASE := Vector3(55.0, -1.2, -52.0)
const COLD := Color(0.12, 0.16, 0.24)
const WARM := Color(1.0, 0.86, 0.6)
const LINGER := 20.0 ## seconds he stays after thumbs_up
const GLOW := 1.0

var _mood := "wave"
var _model: Node3D
var _arm: Node3D
var _arm_rest := Vector3.ZERO
var _materials: Array = []
var _time := 0.0
var _glow := 0.0
var _pop := 0.0
var _linger := 0.0
var _aligned := false


func _ready() -> void:
	add_to_group("portinho_giant")
	position = BASE
	_model = MODEL.create()
	_model.scale = Vector3.ONE * SCALE
	add_child(_model)
	_materials = MODEL.prepare(_model, true, true)
	_arm = _model.find_child("ArmL", true, false) as Node3D
	if _arm:
		_arm_rest = _arm.rotation
	# Faces the lighthouse (the model looks toward -Z).
	var to := Vector3(0.0, 0.0, -12.0) - Vector3(BASE.x, 0.0, BASE.z)
	rotation.y = atan2(-to.x, -to.z)
	visible = false


func _process(delta: float) -> void:
	_linger = maxf(_linger - delta, 0.0)
	var show_it := GameState.portinho_active() or _linger > 0.0
	visible = show_it
	if not show_it:
		_aligned = false
		return
	_time += delta
	_glow = maxf(_glow - delta, 0.0)
	_pop = maxf(_pop - delta * 1.5, 0.0)
	_animate()
	_watch_beam()
	var tint := COLD.lerp(WARM, clampf(_glow / GLOW, 0.0, 1.0))
	for pair: Array in _materials:
		pair[0].albedo_color = pair[1] * tint


func set_mood(mood: String) -> void:
	_mood = mood
	if mood == "thumbs_up":
		_pop = 1.0
		_linger = LINGER


## Where the story scenes look: his face, about 14 m up.
func point() -> Vector3:
	return to_global(Vector3(0.0, 14.2, 0.0))


func _animate() -> void:
	var swing := 0.0
	var sway := 0.0
	var bob := 0.0
	match _mood:
		"wave":
			swing = sin(_time * 2.2) * deg_to_rad(18.0)
			sway = sin(_time * 1.1) * deg_to_rad(3.0)
		"happy":
			swing = sin(_time * 5.5) * deg_to_rad(28.0)
			sway = sin(_time * 2.75) * deg_to_rad(6.0)
			bob = absf(sin(_time * 5.5)) * 0.04
		_: # thumbs_up: the arm stays up
			sway = sin(_time * 0.8) * deg_to_rad(0.6)
	if _arm:
		_arm.rotation = _arm_rest + Vector3(0.0, 0.0, swing)
	var body := _model.find_child("Body", true, false) as Node3D
	if body:
		body.rotation.z = sway
	_model.position.y = bob * SCALE
	_model.scale = Vector3.ONE * SCALE * (1.0 + 0.15 * _pop * _pop)


## Counts one sweep each time the beam arrives on him. A point 10 % of the way along the same
## bearing tells "pointing at him" apart from "pointing at him but too weak to reach".
func _watch_beam() -> void:
	var beacon := get_tree().get_first_node_in_group("beacon")
	if beacon == null or not beacon.has_method("beam_covers"):
		return
	var from: Vector3 = beacon.global_position
	var aligned: bool = beacon.beam_covers(from.lerp(point(), 0.1))
	var reaches: bool = beacon.beam_covers(point())
	if reaches:
		_glow = GLOW
	if aligned and not _aligned and GameState.portinho_active():
		GameState.portinho_sweep(beacon.working(), reaches)
	_aligned = aligned
