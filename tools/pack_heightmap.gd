extends SceneTree
## Converte tools/terrain_height.f32 (gen_heightmap.py) em res://world/terrain_height.res (Image RGBAF 181x151).
## godot-4 --headless --path . --script res://tools/pack_heightmap.gd

func _initialize() -> void:
	var f := FileAccess.open("res://tools/terrain_height.f32", FileAccess.READ)
	var bytes := f.get_buffer(f.get_length())
	var img := Image.create_from_data(181, 151, false, Image.FORMAT_RGBAF, bytes)
	print("save: ", ResourceSaver.save(img, "res://world/terrain_height.res"), " ", img.get_size())
	quit()
