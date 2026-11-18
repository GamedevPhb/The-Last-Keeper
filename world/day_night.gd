extends Node
## Moves the sky from dusk (17:30) through the dark of night to a grey dawn (06:00),
## following the game clock.

## Night is contrast, not black: a cool blue-grey fog/sky a little lighter than the land, so
## silhouettes read against it; a cool moon key with dark (not black) ambient fill; and warm lamp
## pools to navigate by. NIGHT is the look at 21:00; it sinks to DEEP at 03:00 and lifts to DAWN.
const DUSK := {"background": Color(0.55, 0.28, 0.14), "fog": Color(0.5, 0.28, 0.16), "ambient": Color(0.75, 0.5, 0.36), "ambient_energy": 1.0, "fog_end": 75.0, "moon": Color(1.0, 0.62, 0.3), "moon_energy": 1.0}
const NIGHT := {"background": Color(0.11, 0.15, 0.19), "fog": Color(0.1, 0.135, 0.17), "ambient": Color(0.32, 0.4, 0.55), "ambient_energy": 0.42, "fog_end": 45.0, "moon": Color(0.62, 0.74, 1.0), "moon_energy": 0.7}
const DEEP := {"background": Color(0.065, 0.09, 0.12), "fog": Color(0.06, 0.085, 0.11), "ambient": Color(0.28, 0.34, 0.5), "ambient_energy": 0.32, "fog_end": 45.0, "moon": Color(0.55, 0.66, 0.95), "moon_energy": 0.5}
const DAWN := {"background": Color(0.16, 0.2, 0.2), "fog": Color(0.16, 0.2, 0.2), "ambient": Color(0.4, 0.5, 0.5), "ambient_energy": 0.7, "fog_end": 55.0, "moon": Color(0.7, 0.8, 0.8), "moon_energy": 0.4}

## Per-pixel warm pools (psx_lamp_N globals, shaders/psx_common.gdshaderinc): the world lamps
## present when the scene starts, nearest first. LAMP_PIXEL scales their energy (the vertex
## OmniLight3D still lights small props on top).
const LAMP_SLOTS := 4
const LAMP_PIXEL := 1.5
const LAMP_MIN_RANGE := 3.0
const LAMP_VIEW := 50.0 ## lamps farther than this (minus their range) are behind the fog anyway

@export var environment: Environment
@export var moon: DirectionalLight3D


const SUN_AZIMUTH := Vector2(0.56, 0.83)  # horizontal bearing of the sunset (sea, seen from the pier)
const SUN_START := 17.5 * 60.0
const SUN_END := 19.25 * 60.0

var _sky: ShaderMaterial
var _lamps: Array[OmniLight3D] = []


func _ready() -> void:
	if environment and environment.sky:
		_sky = environment.sky.sky_material as ShaderMaterial
	_collect_lamps.call_deferred()


## World-authored lamps (island, details, expansion, beacon glow). Lights spawned later (ships,
## muzzle flash, fuse pilots) and anything under the player are left to vertex lighting.
func _collect_lamps() -> void:
	var main := get_parent()
	var player := main.get_node_or_null("Player")
	for found in main.find_children("*", "OmniLight3D", true, false):
		var light := found as OmniLight3D
		if light.omni_range >= LAMP_MIN_RANGE and not (player and player.is_ancestor_of(light)):
			_lamps.append(light)


func _exit_tree() -> void:
	for i in LAMP_SLOTS:
		RenderingServer.global_shader_parameter_set("psx_lamp_%d" % i, Vector4.ZERO)


func _update_lamps() -> void:
	var cam := get_viewport().get_camera_3d()
	var eye := cam.global_position if cam else Vector3.ZERO
	var near: Array = []
	for light in _lamps:
		if not is_instance_valid(light) or not light.is_visible_in_tree() or light.light_energy <= 0.0:
			continue
		var d := light.global_position.distance_to(eye) - light.omni_range
		if d < LAMP_VIEW:
			near.append([d, light])
	near.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	for i in LAMP_SLOTS:
		var pos := Vector4.ZERO
		var col := Vector4.ZERO
		if i < near.size():
			var light: OmniLight3D = near[i][1]
			var p := light.global_position
			pos = Vector4(p.x, p.y, p.z, light.omni_range)
			var c := light.light_color * light.light_energy * LAMP_PIXEL
			col = Vector4(c.r, c.g, c.b, 0.0)
		RenderingServer.global_shader_parameter_set("psx_lamp_%d" % i, pos)
		RenderingServer.global_shader_parameter_set("psx_lamp_color_%d" % i, col)


func _process(_delta: float) -> void:
	var minutes := GameState.minutes
	var look: Dictionary
	if minutes < 19 * 60 + 15:
		look = _mix(DUSK, NIGHT, smoothstep(17.5 * 60, 19.25 * 60, minutes))
	elif minutes < 27 * 60:
		look = _mix(NIGHT, DEEP, smoothstep(21.0 * 60, 27.0 * 60, minutes))
	elif minutes < 28 * 60 + 30:
		look = DEEP
	else:
		look = _mix(DEEP, DAWN, smoothstep(28.5 * 60, 30.0 * 60, minutes))
	environment.background_color = look.background
	environment.fog_light_color = look.fog
	environment.ambient_light_color = look.ambient
	environment.ambient_light_energy = look.ambient_energy
	environment.fog_depth_end = look.fog_end
	moon.light_color = look.moon
	moon.light_energy = look.moon_energy
	_update_sky(minutes, look)
	_update_lamps()


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
