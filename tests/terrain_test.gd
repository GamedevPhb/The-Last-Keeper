extends SceneTree
## Terreno organico: raio vertical (camada world) nos pontos-chave. Platos devem dar y ~ 0 (ou o piso da estrutura);
## costa/agua abaixo do mar; colinas altas nas bordas. Run: godot-4 --headless --path . --script res://tests/terrain_test.gd

# [nome, x, z, y_esperado, tolerancia]
const CHECKS := [
	["spawn (deck do pier)", 0.4, 49.8, 0.0, 0.15],
	["bau (deck)", -0.7, 47.2, 0.0, 0.15],
	["base do pier", 0.4, 33.0, 0.0, 0.1],
	["porta da casa", 27.25, 10.4, 0.0, 0.1],
	["dentro da casa", 27.25, 7.2, 0.0, 0.3],
	["gerador (galpao)", -19.0, 14.7, 0.0, 0.3],
	["fabrica oleo", -12.0, 21.5, 0.0, 0.1],
	["fabrica comb.", -8.5, 21.5, 0.0, 0.1],
	["entrada do farol", 4.2, -13.5, 0.0, 0.3],
	["pe do farol", 0.0, -3.0, 0.0, 0.1],
	["gruta (corredor)", 31.0, -58.0, 0.0, 0.3],
	["cabana do vigia 6", -62.0, -12.0, 0.0, 0.3],
	["torre do vigia", -67.0, -19.0, 0.0, 0.1],
	["horta", 33.0, -3.0, 0.0, 0.1],
	["cemiterio", -13.0, -25.0, 0.0, 0.1],
	["pesca (pier)", 7.0, -55.0, 0.0, 0.4],
	["praia invasores (-14,33)", -14.0, 33.0, 0.0, 0.1],
	["praia invasores (3,41)", 3.0, 41.0, 0.0, 0.15],
]

var _frames := 0
var _fail := 0


func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())


func _ray(x: float, z: float) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, 40.0, z), Vector3(x, -10.0, z), 1)
	return root.get_world_3d().direct_space_state.intersect_ray(q)


func _process(_d: float) -> bool:
	_frames += 1
	if _frames < 6:
		return false
	for c in CHECKS:
		var hit := _ray(c[1], c[2])
		if hit.is_empty():
			printerr("FALHA %s: sem colisao" % c[0])
			_fail += 1
			continue
		var y: float = hit.position.y
		# dentro de estruturas o raio pode parar no teto; so conta a menor altura se tiver teto
		if absf(y - c[3]) > c[4]:
			var low := _ray_below(c[1], c[2], y)
			if absf(low - c[3]) > c[4]:
				printerr("FALHA %s: y=%.2f esperado %.2f" % [c[0], low, c[3]])
				_fail += 1
	# costa: agua nos pontos de mar, terra alta nas bordas
	var t := preload("res://world/terrain.gd")
	for p in [Vector2(-40, 24), Vector2(3.3, 47.5), Vector2(0.4, 52), Vector2(-92, 0)]:
		if t.height_at(p.x, p.y) > -1.2:
			printerr("FALHA agua esperada em ", p)
			_fail += 1
	for p in [[Vector2(31, -74), 8.0], [Vector2(-50, 17), 4.0], [Vector2(15, -37), 4.0]]:
		if t.height_at(p[0].x, p[0].y) < p[1]:
			printerr("FALHA relevo baixo em ", p[0])
			_fail += 1
	if _fail > 0:
		printerr("TERRAIN TEST FAILED: %d" % _fail)
		quit(1)
	else:
		print("TERRAIN TEST OK")
		quit(0)
	return true


## Menor ponto de colisao abaixo de `y_top` (atravessa tetos de estruturas).
func _ray_below(x: float, z: float, y_top: float) -> float:
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, y_top - 0.2, z), Vector3(x, -10.0, z), 1)
	var hit := root.get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position.y if not hit.is_empty() else -99.0
