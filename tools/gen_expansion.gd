extends SceneTree
## Descartavel: gera res://world/expansion.tscn. Rodar:
## godot-4 --headless --path . --script res://tools/gen_expansion.gd

var root_node: Node3D
var M := {}
var rng := RandomNumberGenerator.new()
var trail: Array[Vector3] = []


func _mat(n: String) -> Material:
	if not M.has(n):
		M[n] = load("res://materials/%s.tres" % n)
	return M[n]


func _add(parent: Node, n: Node, nm: String, pos := Vector3.ZERO) -> Node:
	n.name = nm
	if n is Node3D:
		n.position = pos
	parent.add_child(n)
	n.owner = root_node
	return n


func _box(parent: Node, nm: String, pos: Vector3, size: Vector3, mat: String, rot_y := 0.0, csg := true) -> Node3D:
	var b := CSGBox3D.new()
	b.size = size
	b.material = _mat(mat)
	_add(parent, b, nm, pos)
	b.rotation.y = rot_y
	return b


func _land(parent: Node, nm: String, c: Vector2, r: float, sides := 20, sz := 1.0) -> void:
	var beach := CSGCylinder3D.new()
	beach.radius = r + 2.5
	beach.height = 6.0
	beach.sides = sides
	beach.material = _mat("m_path")
	_add(parent, beach, nm + "Beach", Vector3(c.x, -3.4, c.y))
	beach.scale = Vector3(1, 1, sz)
	var g := CSGCylinder3D.new()
	g.radius = r
	g.height = 6.0
	g.sides = sides
	g.material = _mat("m_ground")
	_add(parent, g, nm, Vector3(c.x, -3.03, c.y))
	g.scale = Vector3(1, 1, sz)


func _res(parent: Node, kind: String, idx: int, pos: Vector3, mesh_mat: String, size: Vector3, amount := 1) -> void:
	var m := Marker3D.new()
	m.set_meta("kind", kind)
	m.set_meta("amount", amount)
	var path := "res://world/resource_node.gd"
	if ResourceLoader.exists(path):
		m.set_script(load(path))
		m.set("kind", kind)
		m.set("amount", amount)
	_add(parent, m, "ResNode_%s_%d" % [kind, idx], pos)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(mesh_mat)
	_add(m, mi, "Mesh", Vector3(0, size.y * 0.5, 0))
	mi.rotation.y = rng.randf() * TAU


func _station(parent: Node, nm: String, pos: Vector3, script_name := "") -> void:
	var m := Marker3D.new()
	if script_name != "":
		m.set_script(load("res://puzzles/%s.gd" % script_name))
	_add(parent, m, nm, pos)


func _dist_seg(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return p.distance_to(a + ab * t)


func _near_trail(p: Vector2, w: float) -> bool:
	for i in trail.size() - 1:
		if _dist_seg(p, Vector2(trail[i].x, trail[i].z), Vector2(trail[i + 1].x, trail[i + 1].z)) < w:
			return true
	return false


func _initialize() -> void:
	rng.seed = 4242
	root_node = Node3D.new()
	root_node.name = "Expansion"

	# ---- Terreno extra (camada world, CSG) ----
	var ground := CSGCombiner3D.new()
	ground.use_collision = true
	_add(root_node, ground, "Ground")
	_land(ground, "Forest", Vector2(-58, -6), 24.0, 28, 32.0 / 24.0)
	_land(ground, "ForestInner", Vector2(-56, -6), 18.0, 24, 30.0 / 18.0)
	_box(ground, "ForestLink", Vector3(-41, -3.03, -4), Vector3(12, 6, 14), "m_ground")
	_box(ground, "NorthLink", Vector3(0, -3.03, -42), Vector3(12, 6, 14), "m_ground")
	_box(ground, "NorthStrip", Vector3(0, -3.03, -52), Vector3(34, 6, 10), "m_ground")
	_box(ground, "NorthBeach", Vector3(0, -3.4, -52), Vector3(39, 6, 15), "m_path")
	_box(ground, "CaveLink", Vector3(22, -3.03, -56), Vector3(12, 6, 8), "m_ground")
	_land(ground, "CaveLand", Vector2(31, -60), 9.5, 20)
	_land(ground, "Islet2", Vector2(50, 42), 9.0, 16)

	# ---- Trilha (mata) ----
	trail = [Vector3(-35, 0, -4), Vector3(-45, 0, -6), Vector3(-53, 0, -9), Vector3(-57.5, 0, -11.5),
		Vector3(-60, 0, -17), Vector3(-67, 0, -19)]
	var trail_n := Node3D.new()
	_add(root_node, trail_n, "Trail")
	for i in trail.size() - 1:
		var a := trail[i]
		var b := trail[i + 1]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.2, 0.04, a.distance_to(b) + 0.6)
		mi.mesh = bm
		mi.material_override = _mat("m_path")
		_add(trail_n, mi, "Seg%d" % i, (a + b) * 0.5 + Vector3(0, 0.0, 0))
		mi.rotation.y = atan2(b.x - a.x, b.z - a.z)

	# ---- Cabana do vigia 6 (ruina) ----
	var cab := CSGCombiner3D.new()
	cab.use_collision = true
	_add(root_node, cab, "WatchHut", Vector3(-62, 0, -12))
	_box(cab, "Floor", Vector3(0, 0.05, 0), Vector3(6.4, 0.2, 5.4), "m_concrete")
	_box(cab, "WallW", Vector3(-3.0, 1.2, 0), Vector3(0.25, 2.4, 5.2), "m_wood")
	_box(cab, "WallS", Vector3(-0.8, 1.0, 2.6), Vector3(4.0, 2.0, 0.25), "m_wood")
	_box(cab, "WallN_A", Vector3(-1.6, 1.2, -2.6), Vector3(2.6, 2.4, 0.25), "m_wood")
	_box(cab, "WallN_B", Vector3(2.0, 0.6, -2.6), Vector3(1.4, 1.2, 0.25), "m_wood")
	_box(cab, "WallE_A", Vector3(3.0, 1.2, -1.6), Vector3(0.25, 2.4, 1.8), "m_wood")
	_box(cab, "WallE_B", Vector3(3.0, 0.8, 1.8), Vector3(0.25, 1.6, 1.4), "m_wood")
	_box(cab, "RoofFallen", Vector3(-1.6, 2.5, -0.4), Vector3(3.4, 0.15, 4.6), "m_deadwood")
	cab.get_node("RoofFallen").rotation.z = 0.25
	_box(cab, "Bunk", Vector3(-2.1, 0.45, 1.5), Vector3(1.8, 0.5, 0.9), "m_deadwood")
	_box(cab, "Table", Vector3(0.6, 0.55, -1.7), Vector3(1.4, 0.1, 0.8), "m_wood")
	_box(cab, "TableLegs", Vector3(0.6, 0.3, -1.7), Vector3(1.1, 0.5, 0.5), "m_deadwood")
	var clue_s: Script = load("res://puzzles/clue.gd")
	var clue: Area3D = Area3D.new()
	clue.set_script(clue_s)
	clue.set("text", "Diário do Vigia 6: a luz chama mais perto a cada noite. O mar devolve coisas que não são navios. Se eu não voltar, não acenda o fogo da cabana.")
	clue.set("prompt", "Ler o diário")
	_add(cab, clue, "Clue_Watch6", Vector3(0.6, 0.95, -1.7))
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.9
	cs.shape = sph
	_add(clue, cs, "Shape")
	var hl := OmniLight3D.new()
	hl.light_color = Color(0.5, 0.75, 0.7)
	hl.light_energy = 0.35
	hl.omni_range = 9.0
	hl.shadow_enabled = false
	_add(cab, hl, "HutLight", Vector3(-1, 2.2, 0))

	# ---- Gruta ----
	var cave := CSGCombiner3D.new()
	cave.use_collision = true
	_add(root_node, cave, "Cave")
	_box(cave, "Mound", Vector3(31, 2.5, -63), Vector3(14, 5, 12), "m_rock")
	_box(cave, "MoundTop", Vector3(30, 5.0, -63), Vector3(9, 3, 8), "m_rock", 0.4)
	var cut := _box(cave, "Corridor", Vector3(31, 1.2, -59.25), Vector3(3, 2.8, 5.5), "m_rock")
	(cut as CSGBox3D).operation = CSGShape3D.OPERATION_SUBTRACTION
	var cut2 := _box(cave, "Chamber", Vector3(31, 1.4, -65.5), Vector3(6, 3.2, 5), "m_rock")
	(cut2 as CSGBox3D).operation = CSGShape3D.OPERATION_SUBTRACTION
	var cl := OmniLight3D.new()
	cl.light_color = Color(0.9, 0.55, 0.3)
	cl.light_energy = 0.25
	cl.omni_range = 7.0
	cl.shadow_enabled = false
	_add(cave, cl, "CaveLight", Vector3(31, 1.6, -65.5))

	# ---- Costa norte: destroços ----
	var wreck := CSGCombiner3D.new()
	wreck.use_collision = true
	_add(root_node, wreck, "Wreck", Vector3(-18, 0, -53))
	_box(wreck, "Keel", Vector3(0, 0.5, 0), Vector3(1.4, 0.7, 7.0), "m_deadwood", 0.5)
	_box(wreck, "RibL", Vector3(-1.0, 1.0, -0.8), Vector3(0.2, 1.8, 4.0), "m_wood", 0.5)
	_box(wreck, "RibR", Vector3(1.0, 0.8, 0.4), Vector3(0.2, 1.4, 3.0), "m_wood", 0.5)
	_box(wreck, "Plate", Vector3(2.8, 0.25, 2.0), Vector3(2.0, 0.15, 1.4), "m_metal", 0.9)
	var posts := Node3D.new()
	_add(root_node, posts, "SaltPosts")
	for i in 4:
		_box(posts, "Post%d" % i, Vector3(-26 + i * 5.0, 0.8, -57.5 + rng.randf() * 1.0), Vector3(0.25, 1.6, 0.25), "m_deadwood")

	var fp := StaticBody3D.new()
	_add(root_node, fp, "FishingPier", Vector3(7, 0.0, -55))
	var fpm := MeshInstance3D.new()
	var fpb := BoxMesh.new()
	fpb.size = Vector3(8, 0.2, 2.2)
	fpm.mesh = fpb
	fpm.material_override = _mat("m_wood")
	_add(fp, fpm, "Mesh")
	var fps := CollisionShape3D.new()
	var fpbs := BoxShape3D.new()
	fpbs.size = fpb.size
	fps.shape = fpbs
	_add(fp, fps, "Shape")
	for i in 3:
		_box(root_node, "FishingPost%d" % i, Vector3(3.5 + i * 3.5, -0.4, -56.2), Vector3(0.25, 1.4, 0.25), "m_deadwood")

	# ---- Pontos de recurso ----
	var res := Node3D.new()
	_add(root_node, res, "Resources")
	# madeira: 8 na mata (fora da trilha)
	var wood_pts := [Vector3(-44, 0, -14), Vector3(-50, 0, -22), Vector3(-48, 0, 2), Vector3(-56, 0, 10),
		Vector3(-66, 0, 2), Vector3(-72, 0, -6), Vector3(-62, 0, -26), Vector3(-74, 0, -16)]
	for i in wood_pts.size():
		_res(res, "wood", i + 1, wood_pts[i], "m_deadwood", Vector3(1.6, 0.3, 0.3), 3)
	var algae := [Vector3(-14, -0.3, -58.6), Vector3(-6, -0.3, -59), Vector3(-20, -0.3, -58.2)]
	for i in algae.size():
		_res(res, "algae", i + 1, algae[i], "m_bush", Vector3(1.2, 0.2, 1.0), 2)
	var fat := [Vector3(-1, -0.3, -58.8), Vector3(12, -0.3, -58.4)]
	for i in fat.size():
		_res(res, "fat", i + 1, fat[i], "m_paper", Vector3(0.9, 0.5, 0.7), 2)
	var coal := [Vector3(29.2, 0, -66), Vector3(32.8, 0, -66.5), Vector3(31, 0, -67.3)]
	for i in coal.size():
		_res(res, "coal", i + 1, coal[i], "m_coal", Vector3(0.7, 0.45, 0.6), 2)
	_res(res, "scrap", 1, Vector3(-15.8, 0, -51.2), "m_metal", Vector3(0.9, 0.3, 0.7), 2)
	_res(res, "scrap", 2, Vector3(-19.8, 0, -55.5), "m_metal", Vector3(0.7, 0.3, 0.9), 2)
	_res(res, "scrap", 3, Vector3(-59.2, 0.2, -14.4), "m_metal", Vector3(0.8, 0.3, 0.6), 2)

	# ---- Estações futuras ----
	var st := Node3D.new()
	_add(root_node, st, "Stations")
	_station(st, "Station_Fishing", Vector3(7, 0, -55), "fishing_spot")
	_station(st, "Station_Workshop", Vector3(-27, 0, 8), "workshop")
	_station(st, "Station_Garden", Vector3(22, 0, 18), "garden")
	_station(st, "Station_Fence", Vector3(27, 0, 7), "fence")
	_station(st, "Station_Watchtower", Vector3(-67, 0, -19), "watchtower")

	# ---- Passagem de maré para o ilhéu 2 ----
	var tide := Node3D.new()
	tide.set_script(load("res://puzzles/tide.gd"))
	tide.set("announce", false)
	_add(root_node, tide, "Causeway2")
	for i in 7:
		var q := Vector3(30, 0, 26).lerp(Vector3(43, 0, 38), i / 6.0)
		var body := StaticBody3D.new()
		_add(tide, body, "Stone%d" % i, Vector3(q.x, -0.55, q.z))
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(2.2, 0.6, 2.2)
		mi.mesh = bm
		mi.material_override = _mat("m_stone")
		_add(body, mi, "Mesh")
		var sh := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = bm.size
		sh.shape = bs
		_add(body, sh, "Shape")
		body.rotation.y = rng.randf() * TAU
	# restos no ilhéu
	_box(root_node, "IsletRock", Vector3(53, 0.8, 44), Vector3(3, 1.6, 2.5), "m_rock", 0.6)

	# ---- Pinheiros (MultiMesh) ----
	var xf: Array[Transform3D] = []
	var guard := 0
	while xf.size() < 230 and guard < 4000:
		guard += 1
		var a := rng.randf() * TAU
		var rr := sqrt(rng.randf())
		var p := Vector2(-58, -6) + Vector2(cos(a) * 21.5, sin(a) * 29.5) * rr
		if p.length() < 38.5 or _near_trail(p, 2.6):
			continue
		if p.distance_to(Vector2(-62, -12)) < 6.5 or p.distance_to(Vector2(-67, -19)) < 4.0:
			continue
		var ok := true
		for w in wood_pts:
			if p.distance_to(Vector2(w.x, w.z)) < 1.8:
				ok = false
		if not ok:
			continue
		var s := 0.8 + rng.randf() * 0.7
		xf.append(Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(p.x, 0, p.y)))
	for p in [Vector2(48, 40), Vector2(53, 40), Vector2(50, 46), Vector2(46, 44)]:
		xf.append(Transform3D(Basis().scaled(Vector3(0.8, 0.8, 0.8)), Vector3(p.x, 0, p.y)))
	var tr := Node3D.new()
	tr.set_script(load("res://world/pines.gd"))
	var spots := PackedFloat32Array()
	for t in xf:
		spots.append_array(PackedFloat32Array([t.origin.x, t.origin.z, t.basis.get_scale().x, t.basis.get_euler().y]))
	tr.set("spots", spots)
	tr.set("trunk_material", _mat("m_deadwood"))
	tr.set("crown_material", _mat("m_pine"))
	_add(root_node, tr, "Pines")
	var body := StaticBody3D.new()
	_add(tr, body, "TrunkColliders")
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 3.0
	for i in xf.size():
		var c := CollisionShape3D.new()
		c.shape = cyl
		_add(body, c, "C%d" % i, xf[i].origin + Vector3(0, 1.5, 0))

	var ps := PackedScene.new()
	ps.pack(root_node)
	print("save: ", ResourceSaver.save(ps, "res://world/expansion.tscn"), " trees=", xf.size())
	quit()
