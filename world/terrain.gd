@tool
extends Node3D
## Terreno organico da ilha: monta em runtime uma malha (normais suaves, cor de vertice) e a colisao (camada 1 `world`)
## a partir de world/terrain_height.res (gerado por tools/gen_heightmap.py + tools/pack_heightmap.gd).
## Canais da imagem: R altura (m), G areia, B mata, A terra batida. Grade de 1 m cobrindo x -92..88, z -82..68.
## `height_at(x, z)` e estatico: scripts e ferramentas usam via `preload("res://world/terrain.gd")`.

const HEIGHT_DATA := "res://world/terrain_height.res"
const X0 := -92.0
const Z0 := -82.0
const SEA_Y := -1.2

const SAND := Color(0.58, 0.52, 0.36)
const GRASS := Color(0.27, 0.33, 0.22)
const FOREST := Color(0.15, 0.24, 0.15)
const ROCK := Color(0.40, 0.39, 0.37)
const DIRT := Color(0.36, 0.28, 0.19)
const SEABED := Color(0.20, 0.21, 0.17)

@export var material: Material

static var _img: Image


static func _image() -> Image:
	if _img == null:
		_img = load(HEIGHT_DATA) as Image
	return _img


## Altura do terreno (bilinear) no ponto do mundo; fora da grade devolve o fundo do mar.
static func height_at(x: float, z: float) -> float:
	var img := _image()
	var fx := x - X0
	var fz := z - Z0
	var w := img.get_width()
	var h := img.get_height()
	if fx < 0.0 or fz < 0.0 or fx > w - 1 or fz > h - 1:
		return SEA_Y - 3.0
	var i := mini(int(fx), w - 2)
	var j := mini(int(fz), h - 2)
	var tx := fx - i
	var tz := fz - j
	var a := img.get_pixel(i, j).r
	var b := img.get_pixel(i + 1, j).r
	var c := img.get_pixel(i, j + 1).r
	var d := img.get_pixel(i + 1, j + 1).r
	return lerpf(lerpf(a, b, tx), lerpf(c, d, tx), tz)


func _ready() -> void:
	for c in get_children():
		c.queue_free()
	var mesh := _build_mesh()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	mi.mesh = mesh
	if material:
		mi.material_override = material
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	if Engine.is_editor_hint():
		return # no editor so a malha; a colisao so em jogo
	var body := StaticBody3D.new()
	body.name = "Body"
	body.collision_layer = 1 # world
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	add_child(body)


func _build_mesh() -> ArrayMesh:
	var img := _image()
	var w := img.get_width()
	var h := img.get_height()
	var hs := PackedFloat32Array()
	hs.resize(w * h)
	for j in h:
		for i in w:
			hs[j * w + i] = img.get_pixel(i, j).r
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	verts.resize(w * h)
	norms.resize(w * h)
	cols.resize(w * h)
	uvs.resize(w * h)
	for j in h:
		for i in w:
			var y := hs[j * w + i]
			var yl := hs[j * w + maxi(i - 1, 0)]
			var yr := hs[j * w + mini(i + 1, w - 1)]
			var yu := hs[maxi(j - 1, 0) * w + i]
			var yd := hs[mini(j + 1, h - 1) * w + i]
			var n := Vector3((yl - yr) / 2.0, 1.0, (yu - yd) / 2.0).normalized()
			var k := j * w + i
			verts[k] = Vector3(X0 + i, y, Z0 + j)
			norms[k] = n
			uvs[k] = Vector2(X0 + i, Z0 + j) * 0.25
			cols[k] = _color(img.get_pixel(i, j), y, n)
	var idx := PackedInt32Array()
	idx.resize((w - 1) * (h - 1) * 6)
	var t := 0
	for j in h - 1:
		for i in w - 1:
			var a := j * w + i
			var b := a + 1
			var c := a + w
			var d := c + 1
			if (i + j) % 2 == 0:
				idx[t] = a; idx[t + 1] = b; idx[t + 2] = c
				idx[t + 3] = b; idx[t + 4] = d; idx[t + 5] = c
			else:
				idx[t] = a; idx[t + 1] = b; idx[t + 2] = d
				idx[t + 3] = a; idx[t + 4] = d; idx[t + 5] = c
			t += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _color(px: Color, y: float, n: Vector3) -> Color:
	var c := GRASS.lerp(FOREST, px.b * 0.75)
	c = c.lerp(DIRT, px.a * 0.6)
	c = c.lerp(SAND, px.g)
	var rock := clampf((1.0 - n.y - 0.2) / 0.2, 0.0, 1.0)
	rock = maxf(rock, clampf((y - 8.0) / 3.0, 0.0, 1.0))
	c = c.lerp(ROCK, rock)
	if y < SEA_Y:
		c = c.lerp(SEABED, clampf((SEA_Y - y) / 0.8, 0.0, 1.0))
	return c
