extends Node3D
## First-person weapons (GDD 4.11): the equipped model in the right hand, procedural sway, swing
## and recoil, reload, and the damage rays. Lives under the Player's Camera3D. The weapon in hand
## is `GameState.equipped`; magazines are `GameState.mags`, spare ammo is in the inventory.
## Targets are the nodes of group "enemies" with `take_damage(amount, direction)`: they are
## tested as vertical capsules (`hit_height`, `hit_radius`) against the ray, behind the world
## (layer 1) so walls stop shots.
##
## Actions: attack (mouse left / R2), reload (T / L2). The hand also reads the hotbar (first
## inventory row): hotbar_1..8 (keys 1-8), hotbar_next / hotbar_prev (mouse wheel, X, d-pad
## right / left); a weapon slot draws it (`GameState.select_hotbar`). Holding the weapon dips it
## while the keeper sprints.

const DEFS := preload("res://items/weapon_defs.gd")
const WORLD_MASK := 1
const MELEE_REACH := 0.25 ## extra radius for the axe: swings are forgiving
const ENEMY_RADIUS := 0.45
const ENEMY_HEIGHT := 1.8
const FLASH_TIME := 0.07
const HINT_GAP := 4.0 ## seconds between "no weapon" / "empty" hints

var player: Node3D
## Seconds left of the current attack cooldown and of the reload (0 = ready).
var cooldown := 0.0
var reload_left := 0.0

var _rig: Node3D
var _model: Node3D
var _shown := ""
var _flash: OmniLight3D
var _flash_left := 0.0
var _raise := 1.0
var _bob := 0.0
var _time := 0.0
var _anim := ""
var _anim_t := 0.0
var _anim_len := 0.0
var _reload_steps := 0
var _hint_left := 0.0
var _was_captured := false
## Radians of muzzle climb still to bring back down (the view settles after a shot).
var _recoil := 0.0


func _ready() -> void:
	_rig = Node3D.new()
	_rig.name = "Rig"
	add_child(_rig)
	_flash = OmniLight3D.new()
	_flash.name = "MuzzleFlash"
	_flash.light_color = Color(1.0, 0.75, 0.4)
	_flash.omni_range = 9.0
	_flash.light_energy = 0.0
	_flash.shadow_enabled = false
	_flash.position = Vector3(0.0, 0.0, -0.8)
	add_child(_flash)
	GameState.weapon_changed.connect(_on_weapon_changed)
	_on_weapon_changed()


## Swings or fires the equipped weapon. True if something happened (swing, shot or dry click).
func attack() -> bool:
	if not _can_act():
		return false
	var id: String = GameState.equipped
	if id == "":
		if _hint_left <= 0.0:
			_hint_left = HINT_GAP
			GameState.say("Mãos vazias. Selecione uma arma na barra de atalhos (1-8 / roda do mouse).")
		GameState.play("unarmed")
		cooldown = 0.4
		return true
	var def: Dictionary = DEFS.get_def(id)
	if reload_left > 0.0 or cooldown > 0.0:
		return false
	if def.ranged:
		if GameState.mags[id] <= 0:
			cooldown = 0.45
			GameState.play("gun_dry")
			if _hint_left <= 0.0:
				_hint_left = HINT_GAP
				GameState.say("Pente vazio. [T] recarrega." if GameState.reserve_ammo(id) > 0 else "Pente vazio e sem munição.")
			return true
		GameState.mags[id] -= 1
		GameState.weapon_changed.emit()
	cooldown = def.cooldown
	_start_anim("swing" if not def.ranged else "kick", 0.55 if not def.ranged else 0.3)
	if def.ranged:
		_fire(id, def)
	else:
		_swing(id, def)
	return true


## Starts a reload (the bullets go into the magazine when it finishes). False if not needed.
func reload() -> bool:
	if not _can_act():
		return false
	var id: String = GameState.equipped
	var def: Dictionary = DEFS.get_def(id)
	if not def.get("ranged", false) or reload_left > 0.0 or cooldown > 0.0:
		return false
	if GameState.mags[id] >= def.mag:
		GameState.say("O pente já está cheio.")
		return false
	if GameState.reserve_ammo(id) <= 0:
		GameState.say("Sem munição para recarregar.")
		return false
	reload_left = def.reload
	_reload_steps = 0
	_start_anim("reload", def.reload)
	return true


func is_reloading() -> bool:
	return reload_left > 0.0


## The weapon model currently in hand (null if bare hands).
func held_model() -> Node3D:
	return _model


## Fires the rays of a shot: damage, noise, flash, recoil. Public so tests can drive it.
func _fire(id: String, def: Dictionary) -> void:
	GameState.play("%s_shot" % id)
	_flash_left = FLASH_TIME
	_flash.light_energy = 2.5
	var origin := global_position
	var forward := -global_transform.basis.z
	var hits := {}
	for i in int(def.pellets):
		var dir := forward if i == 0 else _scatter(forward, def.spread)
		_ray_damage(origin, dir, def, hits, 0.0)
	_apply_hits(hits, forward, def)
	GameState.make_noise(origin, def.noise)
	if player and player.has_method("look_by"):
		_recoil += deg_to_rad(def.kick)
		player.look_by(0.0, deg_to_rad(def.kick))


func _swing(id: String, def: Dictionary) -> void:
	GameState.play("axe_swing")
	var origin := global_position
	var forward := -global_transform.basis.z
	var hits := {}
	_ray_damage(origin, forward, def, hits, MELEE_REACH)
	_apply_hits(hits, forward, def)
	GameState.make_noise(origin, def.noise * (2.0 if not hits.is_empty() else 1.0))


## Casts one ray: the nearest enemy in front of the first wall takes the hit (added to `hits`).
func _ray_damage(origin: Vector3, dir: Vector3, def: Dictionary, hits: Dictionary, reach: float) -> void:
	var end := origin + dir * float(def.range)
	var wall := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin, end, WORLD_MASK))
	var limit: float = float(def.range) if wall.is_empty() else origin.distance_to(wall.position)
	var best: Node = null
	var best_dist := limit
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("take_damage") or enemy.get("dead") == true:
			continue
		var feet: Vector3 = enemy.global_position
		var radius: float = float(enemy.get("hit_radius") if enemy.get("hit_radius") != null else ENEMY_RADIUS) + reach
		var height: float = float(enemy.get("hit_height") if enemy.get("hit_height") != null else ENEMY_HEIGHT)
		var closest := Geometry3D.get_closest_points_between_segments(origin, end, feet, feet + Vector3.UP * height)
		if closest[0].distance_to(closest[1]) > radius:
			continue
		var dist := origin.distance_to(closest[0])
		if dist <= best_dist:
			best = enemy
			best_dist = dist
	if best:
		var dmg: float = def.damage
		if def.get("falloff", 0.0) > 0.0 and def.range > 4.0:
			# the shotgun loses up to `falloff` of its damage between 4 m and its range
			dmg *= 1.0 - def.falloff * clampf((best_dist - 4.0) / (def.range - 4.0), 0.0, 1.0)
		hits[best] = hits.get(best, 0.0) + dmg


func _apply_hits(hits: Dictionary, forward: Vector3, def: Dictionary) -> void:
	for enemy: Node in hits:
		var dir := forward
		dir.y = 0.0
		if enemy.has_method("stagger"):
			enemy.stagger(float(def.stun), float(def.knock))
		enemy.take_damage(hits[enemy], dir.normalized())
		GameState.play("axe_hit" if not def.ranged else "bullet_hit", enemy.global_position + Vector3.UP)


func _scatter(forward: Vector3, spread_deg: float) -> Vector3:
	var frame := global_transform.basis
	var a := randf() * TAU
	var r := deg_to_rad(spread_deg) * sqrt(randf())
	return (forward + frame.x * cos(a) * r + frame.y * sin(a) * r).normalized()


func _can_act() -> bool:
	if not GameState.in_game or GameState.dead or GameState.finished or GameState.panel_open or GameState.scene_active:
		return false
	return player == null or not player.get("locked")


func _on_weapon_changed() -> void:
	var id: String = GameState.equipped
	if id != _shown:
		_shown = id
		reload_left = 0.0
		cooldown = 0.25
		_anim = ""
		_raise = 0.0
		if _model:
			_model.queue_free()
			_model = null
		var def: Dictionary = DEFS.get_def(id)
		if not def.is_empty():
			_model = Actors.item_model(id)
			_model.rotation_degrees = def.tilt
			_rig.add_child(_model)
			_glow(_model)
			GameState.play("gun_equip")


## The viewmodel stays readable in the dark: a faint emission on top of the PS1 lighting.
func _glow(node: Node) -> void:
	for found in node.find_children("*", "MeshInstance3D", true, false):
		var mi := found as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(i) as ShaderMaterial
			if mat:
				mat.set_shader_parameter("emission", Color(0.45, 0.43, 0.4))
				mat.set_shader_parameter("emission_energy", 0.35)


func _start_anim(anim: String, length: float) -> void:
	_anim = anim
	_anim_t = 0.0
	_anim_len = maxf(length, 0.01)


func _process(delta: float) -> void:
	_time += delta
	cooldown = maxf(cooldown - delta, 0.0)
	_hint_left = maxf(_hint_left - delta, 0.0)
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash.light_energy = 0.0
	if GameState.equipped != "" and GameState.inventory.count(GameState.equipped) <= 0:
		GameState.equip("") # dropped it
	if _recoil > 0.0 and player and player.has_method("look_by"):
		var settle := minf(_recoil, delta * 0.4)
		_recoil -= settle
		player.look_by(0.0, -settle)
	_read_input()
	_tick_reload(delta)
	_animate(delta)
	_was_captured = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED


## The wheel "presses and releases" in one event, so polling would miss it.
func _unhandled_input(event: InputEvent) -> void:
	if not _can_act():
		return
	if event.is_action_pressed("hotbar_next"):
		GameState.cycle_hotbar(1)
	elif event.is_action_pressed("hotbar_prev"):
		GameState.cycle_hotbar(-1)


func _read_input() -> void:
	if not _can_act():
		return
	if Input.is_action_just_pressed("attack") and (_was_captured or Input.get_connected_joypads().size() > 0 or TouchControls.enabled):
		attack()
	if Input.is_action_just_pressed("reload"):
		reload()
	for slot in GameState.INVENTORY.HOTBAR:
		if Input.is_action_just_pressed("hotbar_%d" % (slot + 1)):
			GameState.select_hotbar(slot)


func _tick_reload(delta: float) -> void:
	if reload_left <= 0.0:
		return
	var id: String = GameState.equipped
	var def: Dictionary = DEFS.get_def(id)
	reload_left = maxf(reload_left - delta, 0.0)
	var p := 1.0 - reload_left / float(def.reload)
	if _reload_steps == 0 and p >= 0.3:
		_reload_steps = 1
		GameState.play("reload_out")
	if _reload_steps == 1 and p >= 0.75:
		_reload_steps = 2
		GameState.play("reload_in")
	if reload_left <= 0.0:
		var need: int = def.mag - GameState.mags[id]
		var taken := mini(need, GameState.reserve_ammo(id))
		if taken > 0 and GameState.inventory.remove(def.ammo, taken):
			GameState.mags[id] += taken
		GameState.play("reload_close")
		GameState.weapon_changed.emit()


## Pose of the viewmodel: hold + raise-on-equip + walking sway + the attack/reload motion.
func _animate(delta: float) -> void:
	if _model == null:
		return
	var def: Dictionary = DEFS.get_def(_shown)
	_raise = minf(_raise + delta * 3.5, 1.0)
	var speed := 0.0
	var sprint := false
	if player:
		speed = Vector2(player.velocity.x, player.velocity.z).length() if player.is_on_floor() else 0.0
		sprint = GameState.sprinting
	var gait := clampf(speed / 3.5, 0.0, 1.4)
	_bob += delta * (4.0 + speed * 1.7)
	var pos: Vector3 = def.hold
	var rot := Vector3.ZERO
	pos.x += sin(_bob) * 0.012 * gait + sin(_time * 1.1) * 0.002
	pos.y += (absf(cos(_bob)) - 0.5) * 0.02 * gait + sin(_time * 1.5) * 0.003
	rot.z += sin(_bob) * 1.2 * gait
	if sprint:
		pos += Vector3(-0.04, -0.07, 0.04)
		rot += Vector3(-18.0, 12.0, 0.0)
	# raising from the hip
	var lift := 1.0 - ease(_raise, -2.0)
	pos.y -= 0.35 * lift
	rot.x += 35.0 * lift
	if _anim != "":
		_anim_t += delta
		var p := clampf(_anim_t / _anim_len, 0.0, 1.0)
		match _anim:
			"swing":
				# wind-up back, chop forward and down, recover
				var s := 0.0
				if p < 0.3:
					s = -0.7 * ease(p / 0.3, 0.5)
				elif p < 0.5:
					s = lerpf(-0.7, 1.0, ease((p - 0.3) / 0.2, 2.0))
				else:
					s = lerpf(1.0, 0.0, ease((p - 0.5) / 0.5, 0.6))
				rot.x -= 60.0 * s
				rot.z += 25.0 * s
				pos += Vector3(-0.12 * s, -0.08 * s, -0.2 * maxf(s, 0.0))
			"kick":
				var k := (1.0 - p) * (1.0 - p)
				pos.z += 0.09 * k
				pos.y -= 0.02 * k
				rot.x += (14.0 if _shown == "pistol" else 22.0) * k
			"reload":
				var s := sin(PI * p)
				pos.y -= 0.12 * s
				pos.x -= 0.04 * s
				rot.x -= 28.0 * s
				rot.z += (10.0 if _shown == "pistol" else 30.0) * s
		if p >= 1.0:
			_anim = ""
	_rig.position = pos
	_rig.rotation_degrees = rot
