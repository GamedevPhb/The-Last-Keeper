extends SceneTree
## Idempotente, por delta: cada no recebe y += h_novo - h_aplicado, onde h_aplicado vem de
## tools/terrain_height_applied.res (a malha usada na ultima migracao; ausente = cenas ainda nao migradas).
## Ao fim, o heightmap atual vira o `applied`. Rode depois de mudar tools/gen_heightmap.py + pack_heightmap.gd:
## godot-4 --headless --path . --script res://tools/migrate_terrain.gd
## Remove os cilindros CSG "Ground" e reassenta (y += altura do terreno em x,z) os nos em terra de
## world/island_details.tscn e world/expansion.tscn. Platos ficam como estao (altura 0).
## Nao mexe em: Causeway/Causeway2 (pedras de mare), Wreck, Power (fios em y fixo), nos em agua (altura < mar).

const Terrain := preload("res://world/terrain.gd")
const SKIP := ["Causeway", "Causeway2", "Wreck", "Power"]
var moved := 0
var applied: Image


func _initialize() -> void:
	if ResourceLoader.exists("res://tools/terrain_height_applied.res"):
		applied = load("res://tools/terrain_height_applied.res") as Image
	for path in ["res://world/island_details.tscn", "res://world/expansion.tscn"]:
		_run(path)
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://world/terrain_height.res"), ProjectSettings.globalize_path("res://tools/terrain_height_applied.res"))
	DirAccess.copy_absolute(ProjectSettings.globalize_path("res://tools/terrain_height.f32"), ProjectSettings.globalize_path("res://tools/terrain_height_applied.f32"))
	quit()


## Deslocamento efetivo: nos em agua (h < mar) nunca foram reassentados.
func _eff(h: float) -> float:
	return h if h >= Terrain.SEA_Y else 0.0


func _old_h(x: float, z: float) -> float:
	if applied == null:
		return 0.0
	var fx := clampf(x - Terrain.X0, 0.0, applied.get_width() - 1.001)
	var fz := clampf(z - Terrain.Z0, 0.0, applied.get_height() - 1.001)
	var i := int(fx)
	var j := int(fz)
	var tx := fx - i
	var tz := fz - j
	var a := applied.get_pixel(i, j).r
	var b := applied.get_pixel(i + 1, j).r
	var c := applied.get_pixel(i, j + 1).r
	var d := applied.get_pixel(i + 1, j + 1).r
	return _eff(lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz))


func _run(path: String) -> void:
	var root: Node = (load(path) as PackedScene).instantiate()
	moved = 0
	var ground := root.get_node_or_null("Ground")
	if ground:
		root.remove_child(ground)
		ground.free()
	for c in root.get_children():
		_walk(c)
	root.set_meta("terrain_migrated", true)
	var ps := PackedScene.new()
	ps.pack(root)
	print(path, ": reassentados=", moved, " save=", ResourceSaver.save(ps, path))
	root.free()


func _walk(n: Node) -> void:
	if not (n is Node3D) or n.name in SKIP:
		return
	var n3 := n as Node3D
	var p := n3.position
	if p == Vector3.ZERO and n3.rotation == Vector3.ZERO:
		for c in n3.get_children():
			_walk(c)
		return
	var dy := _eff(Terrain.height_at(p.x, p.z)) - _old_h(p.x, p.z) # agua: cota propria (pier, ilhota, destrocos)
	if applied == null and (n3.name.begins_with("ResNode_algae") or n3.name.begins_with("ResNode_fat")):
		dy += 0.1
	if absf(dy) > 0.0005:
		n3.position.y += dy
		moved += 1
