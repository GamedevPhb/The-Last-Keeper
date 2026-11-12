extends Node
## Moves the sky from dusk (17:30) through the dark of night to a grey dawn (06:00),
## following the game clock.

const DUSK := {"background": Color(0.2, 0.13, 0.1), "fog": Color(0.2, 0.13, 0.1), "ambient": Color(0.5, 0.38, 0.3), "ambient_energy": 0.8, "fog_end": 70.0, "moon": Color(1.0, 0.6, 0.4), "moon_energy": 0.5}
const NIGHT := {"background": Color(0.015, 0.03, 0.025), "fog": Color(0.02, 0.04, 0.03), "ambient": Color(0.2, 0.3, 0.26), "ambient_energy": 0.32, "fog_end": 45.0, "moon": Color(0.5, 0.7, 0.6), "moon_energy": 0.14}
const DAWN := {"background": Color(0.16, 0.2, 0.2), "fog": Color(0.16, 0.2, 0.2), "ambient": Color(0.4, 0.5, 0.5), "ambient_energy": 0.7, "fog_end": 55.0, "moon": Color(0.7, 0.8, 0.8), "moon_energy": 0.3}

@export var environment: Environment
@export var moon: DirectionalLight3D


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


func _mix(a: Dictionary, b: Dictionary, k: float) -> Dictionary:
	var out := {}
	for key: String in a:
		out[key] = lerp(a[key], b[key], k)
	return out
