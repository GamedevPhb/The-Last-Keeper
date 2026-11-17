extends SceneTree
## Headless test of the basic combat: equip, magazines and spare ammo, damage to a Lavado,
## shotgun falloff, empty click, noise and the save round trip.
## Run: godot-4 --headless --path . --script res://tests/weapons_test.gd

var _failures := 0
var _frame := 0
var _sounds: Array[String] = []
var _noises := 0
var _wall: Node3D
var _behind: Node3D


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	if _frame < 2:
		return false
	if _frame == 3:
		return _second()
	if _frame > 3:
		return false
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var player = main.get_node("Player")
	var weapons: Node3D = player.get_node("Head/Camera3D/Weapons")
	var lavados: Node3D = main.find_child("Lavados", true, false)
	state.in_game = true
	var inv = state.inventory
	state.sound.connect(func(sound_name: String, _at: Vector3) -> void: _sounds.append(sound_name))
	state.noise_made.connect(func(_at: Vector3, _radius: float) -> void: _noises += 1)

	_check(weapons != null and lavados != null, "player has Weapons and the island has Lavados")
	_check(not state.equip("axe") and state.equipped == "", "cannot equip what is not carried")
	for id in ["axe", "pistol", "shotgun", "ammo_pistol", "shells"]:
		_check(state.INVENTORY.ITEMS.has(id), "%s is an item" % id)
		_check(state.INVENTORY.item_name(id) != id, "%s has a PT-BR name" % id)

	# bare hands
	weapons.cooldown = 0.0
	_check(weapons.attack() and _sounds.has("unarmed"), "bare hands: only a whoosh")

	# the chest gives the axe
	var chest: Node = main.find_child("Chest", true, false)
	chest._on_open(player)
	_check(inv.count("axe") == 1, "the chest holds the axe")

	# the axe
	_check(state.equip("axe") and state.equipped == "axe", "axe equipped")
	_check(weapons.held_model() != null, "axe viewmodel is built")
	var foe := _lavado(lavados, player, 1.5)
	weapons.cooldown = 0.0
	_check(weapons.attack(), "axe swings")
	_check(is_equal_approx(foe.health, 35.0), "axe does 25 (hp %s)" % foe.health)
	_check(_sounds.has("axe_swing") and _sounds.has("axe_hit"), "swing and hit sounds")
	_check(_noises > 0, "swinging makes noise")
	_check(weapons.attack() == false, "cooldown blocks the next swing")
	weapons.cooldown = 0.0
	weapons.attack()
	weapons.cooldown = 0.0
	weapons.attack()
	_check(foe.dead and not lavados.walkers().has(foe), "three axe hits kill a Lavado")
	_check(not foe.is_in_group("enemies"), "the dead leave the enemies group")
	var far := _lavado(lavados, player, 4.0)
	weapons.cooldown = 0.0
	weapons.attack()
	_check(is_equal_approx(far.health, 60.0), "the axe does not reach 4 m")
	far.take_damage(100.0)

	# the pistol: empty magazine, reload, fire
	state.give("pistol", 1)
	_check(state.equip("pistol") and weapons.held_model() != null, "pistol equipped")
	var target := _lavado(lavados, player, 8.0)
	weapons.cooldown = 0.0
	var shots_before := _sounds.size()
	_check(weapons.attack() and state.mags.pistol == 0 and is_equal_approx(target.health, 60.0), "no ammo: dry click, no damage")
	_check(_sounds.has("gun_dry"), "dry click sound")
	weapons.cooldown = 0.0
	_check(not weapons.reload(), "nothing to reload with")
	state.give("ammo_pistol", 8)
	_check(weapons.reload() and weapons.is_reloading(), "reload starts")
	weapons.cooldown = 0.0
	_check(not weapons.attack(), "cannot fire while reloading")
	weapons._tick_reload(5.0)
	_check(state.mags.pistol == 6 and inv.count("ammo_pistol") == 2, "reload moves 6 rounds to the magazine")
	weapons.cooldown = 0.0
	_check(weapons.attack() and state.mags.pistol == 5, "a shot spends a round")
	_check(is_equal_approx(target.health, 25.0), "pistol does 35 at 8 m (hp %s)" % target.health)
	_check(_sounds.has("pistol_shot"), "shot sound")
	weapons.cooldown = 0.0
	weapons.attack()
	_check(target.dead, "two pistol shots kill")

	# a wall stops the bullet
	var behind := _lavado(lavados, player, 6.0)
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4.0, 4.0, 0.2)
	shape.shape = box
	wall.add_child(shape)
	main.add_child(wall)
	wall.global_position = player.global_position + Vector3(0.0, 1.5, -3.0)
	_wall = wall
	_behind = behind
	return false


## Second frame: the wall is registered in the physics server by now.
func _second() -> bool:
	var state := root.get_node("GameState")
	var main := root.get_node("Main")
	var player = main.get_node("Player")
	var weapons: Node3D = player.get_node("Head/Camera3D/Weapons")
	var lavados: Node3D = main.find_child("Lavados", true, false)
	var inv = state.inventory
	weapons.cooldown = 0.0
	weapons.attack()
	_check(is_equal_approx(_behind.health, 60.0), "walls block shots")
	_wall.free()
	_behind.take_damage(100.0)

	# the shotgun
	state.give("shotgun", 1)
	state.give("shells", 4)
	_check(state.equip("shotgun"), "shotgun equipped")
	weapons.cooldown = 0.0
	_check(weapons.reload(), "shotgun reload")
	weapons._tick_reload(10.0)
	_check(state.mags.shotgun == 2 and inv.count("shells") == 2, "two shells loaded")
	var close := _lavado(lavados, player, 2.0)
	weapons.cooldown = 0.0
	weapons.attack()
	_check(close.dead and state.mags.shotgun == 1, "shotgun kills at point blank, one shell")
	var distant := _lavado(lavados, player, 18.0)
	weapons.cooldown = 0.0
	weapons.attack()
	_check(distant.health > 0.0 and distant.health < 60.0, "shotgun falls off with distance (hp %s)" % distant.health)

	# noise draws Lavados
	state.make_noise(player.global_position + Vector3(0.0, 0.0, -10.0), 40.0)
	_check(distant.alert > 0.0, "a loud noise alerts Lavados in range")

	# impact: flash and shake when an enemy emerges near, with a cooldown and the option
	var impact: Node = main.get_node("Impact")
	var fired := [0]
	state.impact.connect(func(_f: bool, _s: float) -> void: fired[0] += 1)
	state._last_impact = -100.0
	_check(state.enemy_emerged(player.global_position + Vector3(0, 0, -20)), "an enemy emerging nearby fires the impact")
	impact._process(0.0)
	_check(impact.is_active() and impact._rect.color.a > 0.0, "flash is on")
	_check(not state.enemy_emerged(player.global_position + Vector3(0, 0, -20)), "1.5 s cooldown between emerges")
	state._last_impact = -100.0
	_check(not state.enemy_emerged(player.global_position + Vector3(0, 0, -200)), "far emerges do not fire")
	_check(is_equal_approx(impact.step_alpha(0.5), impact.step_alpha(0.4)) and impact.step_alpha(0.0) == 0.0, "flash alpha is stepped")
	impact._process(1.0)
	_check(not impact.is_active() and impact._rect.color.a == 0.0, "flash and shake end")
	var settings := root.get_node("Settings")
	settings.values["impact"] = false
	state._last_impact = -100.0
	state.impact_fx()
	impact._process(0.0)
	_check(not impact.is_active(), "the option turns the impact off")
	settings.values["impact"] = true

	# cycling and slots
	state.equip("")
	state.cycle_weapon()
	_check(state.equipped == "axe", "cycle: hands -> axe")
	state.cycle_weapon()
	state.cycle_weapon()
	state.cycle_weapon()
	_check(state.equipped == "", "cycle: back to bare hands after the shotgun")
	Input.action_press("weapon_2")
	weapons._read_input()
	Input.action_release("weapon_2")
	_check(state.equipped == "pistol", "key 2 equips the pistol")

	# save round trip
	var pistol_rounds: int = state.mags.pistol
	var shotgun_rounds: int = state.mags.shotgun
	var saved: Dictionary = state.to_save()
	state.equip("")
	state.mags.pistol = 0
	state.from_save(saved)
	_check(state.equipped == "pistol" and state.mags.pistol == pistol_rounds and state.mags.shotgun == shotgun_rounds and pistol_rounds > 0, "equipped weapon and magazines survive a save")
	state.equipped = "axe"
	inv.remove("axe", 1)
	saved = state.to_save()
	state.from_save(saved)
	_check(state.equipped == "", "a weapon that is no longer carried is not equipped on load")

	# dropping the weapon holsters it
	state.equip("pistol")
	inv.remove("pistol", 1)
	weapons._process(0.016)
	_check(state.equipped == "", "dropping the weapon puts it away")

	if _failures > 0:
		printerr("WEAPONS TEST FAILED: %d checks" % _failures)
		quit(1)
	else:
		print("WEAPONS TEST PASSED")
		quit(0)
	return true


## A Lavado `distance` meters in front of the player (the pier faces -Z at the start).
func _lavado(lavados: Node3D, player: Node3D, distance: float) -> Node3D:
	player.get_node("Head").rotation.x = 0.0 # undo the recoil of the last shot
	lavados._spawn(0)
	var foe: Node3D = lavados.walkers()[-1]
	foe.global_position = player.global_position + Vector3(0.0, 0.0, -distance)
	return foe


func _check(ok: bool, what: String) -> void:
	if not ok:
		_failures += 1
		printerr("FAIL: ", what)
