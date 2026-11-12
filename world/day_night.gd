extends Node
## Moves the sky from dusk (17:30) through the dark of night to a grey dawn (06:00),
## following the game clock.

const DUSK := {"background": Color(0.55, 0.28, 0.14), "fog": Color(0.5, 0.28, 0.16), "ambient": Color(0.75, 0.5, 0.36), "ambient_energy": 1.0, "fog_end": 75.0, "moon": Color(1.0, 0.62, 0.3), "moon_energy": 1.0}
const NIGHT := {"background": Color(0.015, 0.03, 0.025), "fog": Color(0.02, 0.04, 0.03), "ambient": Color(0.2, 0.3, 0.26), "ambient_energy": 0.32, "fog_end": 45.0, "moon": Color(0.5, 0.7, 0.6), "moon_energy": 0.14}
const DAWN := {"background": Color(0.16, 0.2, 0.2), "fog": Color(0.16, 0.2, 0.2), "ambient": Color(0.4, 0.5, 0.5), "ambient_energy": 0.7, "fog_end": 55.0, "moon": Color(0.7, 0.8, 0.8), "moon_energy": 0.3}

@export var environment: Environment
@export var moon: DirectionalLight3D


const SUN_AZIMUTH := Vector2(0.56, 0.83)  # horizontal bearing of the sunset (sea, seen from the pier)
const SUN_START := 17.5 * 60.0
const SUN_END := 19.25 * 60.0

var _sky: ShaderMaterial


func _ready() -> void:
	if environment and environment.sky:
		_sky = environment.sky.sky_material as ShaderMaterial


func _process(_delta: float) -> void:
	var minutes := GameState.minutes
	var look: Dictionary
	if minutes < 19 * 60 + 15:
		look = _mix(DUSK, NIGHT, smoothstep(17.5 * 60, 19.25 * 60, minutes))
	elif minutes < 28 * 60 + 30:
		look = NIGHT
	else:
		look = _mix(NIGHT, DAWN, smoothstep(28.5 * 60, 30.0 * 60, minutes))
	environment.background_color = look.background
	environment.fog_light_color = look.fog
	environment.ambient_light_color = look.ambient
	environment.ambient_light_energy = look.ambient_energy
	environment.fog_depth_end = look.fog_end
	moon.light_color = look.moon
	moon.light_energy = look.moon_energy
	_update_sky(minutes, look)


func _update_sky(minutes: float, look: Dictionary) -> void:
	if _sky == null:
		return
	var t := clampf((minutes - SUN_START) / (SUN_END - SUN_START), 0.0, 1.0)
	var elev := deg_to_rad(lerpf(7.0, -7.0, t))
	var h := SUN_AZIMUTH.normalized() * cos(elev)
	var dusk := 1.0 - smoothstep(0.55, 1.0, t)
	if minutes > 24.0 * 60.0:
		dusk = 0.0
	_sky.set_shader_parameter("sun_dir", Vector3(h.x, sin(elev), h.y))
	_sky.set_shader_parameter("sun_strength", dusk)
	_sky.set_shader_parameter("bank_strength", dusk)
	_sky.set_shader_parameter("horizon", look.background)
	_sky.set_shader_parameter("zenith", (look.background as Color).darkened(0.55))
	_sky.set_shader_parameter("time_s", Time.get_ticks_msec() * 0.001)


func _mix(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var out := {}
	for key: String in a:
		out[key] = lerp(a[key], b[key], k)
	return out
