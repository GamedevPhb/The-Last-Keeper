class_name Beacon
extends Node3D
## The lighthouse lamp: an oil-vapour burner run from one brass console (GDD 4.1.1).
## Oil only turns into flame with a hot vaporiser and a pressurised tank. Once lit the
## burner eats oil, leaks pressure, unwinds the clockwork and soots the lens, each at its
## own pace. The panel is `LampConsole`; this node is the model and the physical feedback
## (flame colour, head rotation, beam reach, smoke and the needle gauge on the housing).

## Preloaded instead of the class_name, so the beacon compiles even before the global class cache is rebuilt.
const LAMP_CONSOLE := preload("res://ui/lamp_console.gd")

## The ratchet pulse: tapping CORDA near it winds more. The console flashes on it.
signal beat

const PUMP_STEP := 8.0
const PUMP_COOLDOWN := 0.25
const HEAT_RATE := 20.0 ## per second while AQUECER is held
const COOL_RATE := 4.0 ## per second without a flame
const LIT_TEMP := 80.0
const TEMP_GREEN := 70.0
const FLAME_MIN_PRESSURE := 25.0
const SAFETY_PRESSURE := 90.0
const SAFETY_DUMP_TO := 70.0
const OIL_PER_CAN := 50.0
const FILL_TIME := 1.5
const CLEAN_TIME := 3.0
const WIND_HIT := 10.0
const WIND_MISS := 3.0
const WIND_SLIP := 20.0
const WIND_MAX_MISSES := 3
const BEAT_WINDOW := 0.15
const DROWN_LOCK := 8.0
const DROWN_DIRT := 25.0
const FLARE_DIRT := 15.0
const PFFT_OIL := 2.0
## Below this reach (0..1) ships treat the light as failing.
const MIN_RANGE := 0.4

@export var rotation_speed := 0.6 ## radians per second at full spring
@export var oil_burn := 100.0 / 240.0 ## per second, before progress and pressure
@export var spring_unwind := 100.0 / 150.0 ## per second, unless the motor circuit is powered
@export var dirt_rate := 100.0 / 360.0 ## per second, before progress and pressure
## Off for the menu showcase: gauges freeze but the head keeps turning.
@export var simulate_burner := true

var lit := false:
	set(value):
		lit = value
		GameState.lamp_lit = value
		_sync_working()
## All gauges run 0..100. `dirt` is soot on the lens; the LENTE gauge shows 100 - dirt.
var oil := 0.0
var temp := 0.0
var pressure := 0.0
var wound := 0.0
var dirt := 50.0
var valve_open := false
## Seconds the valve stays jammed after drowning the burner.
var valve_lock := 0.0
var misses := 0
var gusts := 0

var _pump_wait := 0.0
var _beat_time := 0.0
var _gust_in := 75.0
var _flicker := 0.0
var _band := Vector2i.ZERO
var _console: Node
var _bulb_mat: StandardMaterial3D
var _beam_mat: StandardMaterial3D
var _needles: Array[Node3D] = []
var _dials: Array[MeshInstance3D] = []
var _smoke: CPUParticles3D
var _soot: CPUParticles3D

@onready var _head: Node3D = $Head
@onready var _bulb: MeshInstance3D = $Bulb
@onready var _glow: OmniLight3D = $Glow
@onready var _spot: SpotLight3D = $Head/Spot
@onready var _beam: MeshInstance3D = $Head/Beam
@onready var _switch: Interactable = $Interactable


func _ready() -> void:
	add_to_group("saveable")
	_switch.prompt = "Console da lâmpada"
	_switch.hold_time = 0.0
	_bulb_mat = (_bulb.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	_bulb.set_surface_override_material(0, _bulb_mat)
	_beam_mat = (_beam.get_surface_override_material(0) as StandardMaterial3D).duplicate()
	_beam.set_surface_override_material(0, _beam_mat)
	_gust_in = randf_range(60.0, 90.0)
	for angle: float in [0.0, PI]:
		_add_gauge(angle)
	_smoke = _make_smoke(Color(0.55, 0.55, 0.52, 0.55), false)
	_soot = _make_smoke(Color(0.04, 0.04, 0.04, 0.85), true)
	_update_visuals()


func _process(delta: float) -> void:
	if simulate_burner:
		simulate(delta)
	else:
		_spin(delta)
	_update_visuals()


## The menu shows the lamp burning steadily.
func showcase() -> void:
	simulate_burner = false
	oil = 100.0
	wound = 100.0
	pressure = 60.0
	temp = LIT_TEMP
	dirt = 0.0
	valve_open = true
	lit = true


func save_state() -> Dictionary:
	return {"oil": oil, "temp": temp, "pressure": pressure, "wound": wound, "dirt": dirt,
		"valve_open": valve_open, "valve_lock": valve_lock, "lit": lit}


func load_state(data: Dictionary) -> void:
	oil = data.get("oil", oil)
	temp = data.get("temp", temp)
	pressure = data.get("pressure", pressure)
	wound = data.get("wound", wound)
	dirt = data.get("dirt", dirt)
	valve_open = data.get("valve_open", false)
	valve_lock = data.get("valve_lock", 0.0)
	lit = data.get("lit", false)


# ---- Rules

func progress() -> float:
	return GameState.progress()


func green_low() -> float:
	return lerpf(45.0, 50.0, progress())


func green_high() -> float:
	return lerpf(75.0, 68.0, progress())


## Start of the top third of the green band: longer reach, hungrier flame.
func boost_from() -> float:
	return green_high() - (green_high() - green_low()) / 3.0


func beat_period() -> float:
	return lerpf(0.8, 0.55, progress())


func pressure_in_green() -> bool:
	return pressure >= green_low() and pressure <= green_high()


## Pressure's share of the beam reach: weak below the green, +20 % in its top third.
func pressure_factor() -> float:
	if pressure >= boost_from():
		return 1.2
	if pressure >= green_low():
		return 1.0
	return lerpf(0.6, 1.0, clampf((pressure - FLAME_MIN_PRESSURE) / (green_low() - FLAME_MIN_PRESSURE), 0.0, 1.0))


## Beam reach, 0 when dark. 1.0 is a clean lens at normal pressure; can reach 1.2.
func beam_range() -> float:
	if not lit:
		return 0.0
	return (1.0 - dirt / 100.0) * pressure_factor()


func is_fixed() -> bool:
	return wound <= 0.0


## Lit, turning and reaching far enough for ships to read it.
func working() -> bool:
	return lit and not is_fixed() and beam_range() >= MIN_RANGE


func status_text() -> String:
	if valve_lock > 0.0:
		return "AFOGADA %ds" % ceili(valve_lock)
	if not lit:
		return "SEM CHAMA · válvula aberta" if valve_open else "APAGADA"
	var text := "ACESA · alcance %d%%" % roundi(beam_range() * 100.0)
	if is_fixed():
		text += " · FIXA"
	return text


func can_refuel() -> bool:
	return GameState.oil_cans > 0


func simulate(delta: float) -> void:
	var p := progress()
	_pump_wait = maxf(_pump_wait - delta, 0.0)
	valve_lock = maxf(valve_lock - delta, 0.0)
	_flicker = maxf(_flicker - delta, 0.0)
	_beat_time += delta
	var period := beat_period()
	if _beat_time >= period:
		_beat_time = fmod(_beat_time, period)
		beat.emit()
	_update_gusts(delta, p)

	if lit:
		# The flame keeps the vaporiser at 80 (gusts and AQUECER only nudge it).
		temp = move_toward(temp, LIT_TEMP, COOL_RATE * delta)
		pressure = maxf(pressure - 0.25 * (1.0 + p) * delta, 0.0)
		var oil_mult := 1.0
		var dirt_mult := 1.0
		if pressure > green_high():
			oil_mult = 1.3
			dirt_mult = 3.0
		elif pressure >= boost_from():
			oil_mult = 1.3
			dirt_mult = 1.5
		elif pressure < green_low():
			oil_mult = 0.8
		oil = maxf(oil - oil_burn * (1.0 + p) * oil_mult * delta, 0.0)
		dirt = minf(dirt + dirt_rate * (1.0 + p) * dirt_mult * delta, 100.0)
		if not GameState.powered("motor"):
			wound = maxf(wound - spring_unwind * delta, 0.0)
		if oil <= 0.0:
			_go_out("o óleo acabou")
		elif pressure < FLAME_MIN_PRESSURE:
			_flame_out()
	else:
		temp = maxf(temp - COOL_RATE * delta, 0.0)
		pressure = maxf(pressure - 0.5 * delta, 0.0)
		if valve_open:
			# Flame lost with the valve still open: it relights while the vaporiser is hot.
			if temp < TEMP_GREEN or oil <= 0.0:
				valve_open = false
				GameState.say("O queimador esfriou e a válvula fechou. Aqueça de novo.")
			elif pressure >= green_low():
				lit = true
				GameState.play("lamp_valve", global_position)
	_spin(delta)
	_sync_working()


func _update_gusts(delta: float, p: float) -> void:
	if p < 0.5:
		return
	_gust_in -= delta
	if _gust_in > 0.0:
		return
	_gust_in = randf_range(60.0, 90.0) * lerpf(1.0, 0.5, (p - 0.5) * 2.0)
	gusts += 1
	pressure = maxf(pressure - 15.0, 0.0)
	temp = maxf(temp - 20.0, 0.0)
	_flicker = 1.5
	GameState.play("gust", global_position)


func _spin(delta: float) -> void:
	if lit:
		_head.rotate_y(rotation_speed * delta * clampf(wound / 50.0, 0.0, 1.0))


# ---- Actions (called by the console, or directly by tests)

## Pours one can (+50). Without a can nothing happens but the warning.
func refuel() -> bool:
	if not can_refuel():
		GameState.say("Sem óleo. O tambor está no ilhéu, e só dá para chegar na maré baixa.")
		return false
	GameState.oil_cans -= 1
	oil = minf(oil + OIL_PER_CAN, 100.0)
	return true


func heat(delta: float) -> void:
	temp = minf(temp + HEAT_RATE * delta, 100.0)


func pump() -> bool:
	if _pump_wait > 0.0:
		return false
	_pump_wait = PUMP_COOLDOWN
	pressure = minf(pressure + PUMP_STEP, 100.0)
	GameState.play("lamp_pump", global_position)
	if pressure > SAFETY_PRESSURE:
		pressure = SAFETY_DUMP_TO
		GameState.play("lamp_hiss", global_position)
		GameState.say("A válvula de segurança chia e despeja a pressão.")
	return true


func toggle_valve() -> void:
	if valve_open:
		valve_open = false
		lit = false
		GameState.play("lamp_ratchet", global_position)
		return
	if valve_lock > 0.0:
		GameState.play("jam", global_position)
		GameState.say("A válvula está travada de fuligem (%ds)." % ceili(valve_lock))
		return
	if oil <= 0.0:
		GameState.play("lamp_pfft", global_position)
		GameState.say("O tanque está seco. Abasteça antes.")
		return
	if temp < TEMP_GREEN:
		_drown()
		return
	if pressure < green_low():
		oil = maxf(oil - PFFT_OIL, 0.0)
		GameState.play("lamp_pfft", global_position)
		GameState.say("Pfft. Pressão baixa: o óleo escorre sem chama.")
		return
	valve_open = true
	lit = true
	GameState.lamp_lit_once = true
	GameState.autosave()
	GameState.play("lamp_valve", global_position)
	if pressure > green_high():
		dirt = minf(dirt + FLARE_DIRT, 100.0)
		_soot.restart()
		GameState.say("Labareda! A chama pega, mas a lente enegrece.")


## A tap on the ratchet: on the pulse it winds +10, off it +3; three misses in a row slip.
## Returns how much the spring changed.
func wind() -> float:
	var before := wound
	var period := beat_period()
	var off_beat := minf(_beat_time, period - _beat_time)
	if off_beat <= BEAT_WINDOW:
		wound = minf(wound + WIND_HIT, 100.0)
		misses = 0
	else:
		wound = minf(wound + WIND_MISS, 100.0)
		misses += 1
		if misses >= WIND_MAX_MISSES:
			misses = 0
			wound = maxf(wound - WIND_SLIP, 0.0)
			GameState.play("jam", global_position)
			GameState.say("A catraca escapou! Acompanhe o pulso.")
			return wound - before
	GameState.play("lamp_ratchet", global_position)
	return wound - before


func clean() -> void:
	dirt = 0.0


func _drown() -> void:
	dirt = minf(dirt + DROWN_DIRT, 100.0)
	temp = 0.0
	pressure = maxf(pressure - 20.0, 0.0)
	valve_lock = DROWN_LOCK
	_soot.restart()
	GameState.play("lamp_fail", global_position)
	GameState.say("A lâmpada afogou: óleo frio não vaporiza. Aqueça até o verde antes de abrir.")


func _flame_out() -> void:
	lit = false
	GameState.play("lamp_pfft", global_position)
	GameState.say("A chama apagou: pressão baixa. Bombeie já, enquanto o queimador está quente.")


func _go_out(reason: String) -> void:
	valve_open = false
	lit = false
	GameState.say("A lâmpada apagou: %s." % reason)


func _sync_working() -> void:
	var ok := working()
	if GameState.lamp_working != ok:
		GameState.lamp_working = ok


func _on_interacted(by: Node) -> void:
	if _console == null:
		_console = LAMP_CONSOLE.new()
		_console.beacon = self
		add_child(_console)
	_console.open(by as Player)


# ---- Physical feedback

func _update_visuals() -> void:
	_head.visible = lit
	_bulb.visible = lit
	_glow.visible = lit
	_smoke.emitting = lit and pressure > green_high()
	for needle in _needles:
		needle.rotation.z = lerpf(2.3, -2.3, pressure / 100.0)
	var band := Vector2i(roundi(green_low()), roundi(green_high()))
	if band != _band:
		_band = band
		var tex := _dial_texture()
		for dial in _dials:
			(dial.material_override as StandardMaterial3D).albedo_texture = tex
	if not lit:
		return
	var color := Color(1.0, 0.85, 0.5)
	var energy := 1.5
	if pressure < green_low():
		color = Color(1.0, 0.5, 0.15)
		energy = 0.8 * (0.7 + 0.3 * randf())
	elif pressure > green_high():
		color = Color(1.0, 0.97, 0.9)
		energy = 2.0
	if _flicker > 0.0:
		energy *= 0.4 + 0.6 * randf()
	_bulb_mat.albedo_color = color
	_glow.light_color = color
	_glow.light_energy = energy
	var reach := clampf(beam_range(), 0.1, 1.2)
	_spot.spot_range = 90.0 * reach
	_spot.light_energy = 6.0 * clampf(reach, 0.25, 1.2) * (energy / 1.5 if _flicker > 0.0 else 1.0)
	_spot.light_color = color
	_beam_mat.albedo_color = Color(color.r, color.g * 0.96, color.b * 0.9, 0.12 * clampf(reach, 0.2, 1.2))


## A brass manometer on the housing, readable without opening the console.
func _add_gauge(angle: float) -> void:
	var holder := Node3D.new()
	holder.rotation.y = angle
	add_child(holder)
	var dial := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.24, 0.24)
	dial.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	dial.material_override = mat
	dial.position = Vector3(0.0, -0.66, 0.47)
	holder.add_child(dial)
	_dials.append(dial)
	var pivot := Node3D.new()
	pivot.position = dial.position + Vector3(0.0, 0.0, 0.006)
	holder.add_child(pivot)
	var needle := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.012, 0.09, 0.004)
	needle.mesh = box
	needle.position = Vector3(0.0, 0.04, 0.0)
	var needle_mat := StandardMaterial3D.new()
	needle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	needle_mat.albedo_color = Color(0.9, 0.15, 0.1)
	needle.material_override = needle_mat
	pivot.add_child(needle)
	_needles.append(pivot)
	var post := MeshInstance3D.new()
	var stem := BoxMesh.new()
	stem.size = Vector3(0.04, 0.2, 0.04)
	post.mesh = stem
	post.position = Vector3(0.0, -0.55, 0.45)
	post.material_override = ($Housing as MeshInstance3D).get_surface_override_material(0)
	holder.add_child(post)


## 32x32 dial face: bone disc, red below 25 and above 90, green band for the current night.
func _dial_texture() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(15.5, 15.5)
	for y in 32:
		for x in 32:
			var off := Vector2(x, y) - center
			var dist := off.length()
			if dist > 15.5:
				continue
			var c := Color(0.82, 0.78, 0.64)
			if dist > 14.0:
				c = UiKit.BRASS.darkened(0.2)
			elif dist > 9.5:
				# Needle sweeps from 2.3 rad left of up (0) to 2.3 rad right (100).
				var a := atan2(off.x, -off.y)
				var value := (a + 2.3) / 4.6 * 100.0
				if value >= 0.0 and value <= 100.0:
					if value < FLAME_MIN_PRESSURE or value > SAFETY_PRESSURE:
						c = UiKit.BLOOD
					elif value >= _band.x and value <= _band.y:
						c = Color(0.2, 0.6, 0.25)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _make_smoke(color: Color, one_shot: bool) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.3, 0.3)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	particles.mesh = quad
	particles.position = Vector3(0.0, 0.35, 0.0)
	particles.amount = 28 if one_shot else 10
	particles.lifetime = 2.5
	particles.one_shot = one_shot
	particles.explosiveness = 0.8 if one_shot else 0.0
	particles.emitting = false
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.2
	particles.direction = Vector3.UP
	particles.spread = 25.0
	particles.gravity = Vector3(0.0, 0.5, 0.0)
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.8
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 2.0
	particles.color = color
	add_child(particles)
	return particles
