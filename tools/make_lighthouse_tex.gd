extends SceneTree
## Gera materials/lighthouse_stripes.png (32x64): azul degrade (topo escuro -> base claro) com faixas cinza-claro.
## Uso: godot-4 --headless --path . --script res://tools/make_lighthouse_tex.gd
func _initialize() -> void:
	var w := 32
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var top := Color("0066DD")
	var bot := Color("0099DD")
	var light := Color("D8D8D8")
	# faixas claras (linhas, v=0 no topo): 3 faixas de 6 linhas, a de baixo mais larga
	var bands := [[14, 19], [30, 35], [47, 54]]
	for y in h:
		var c := top.lerp(bot, float(y) / (h - 1))
		for b in bands:
			if y >= b[0] and y <= b[1]:
				c = light
		for x in w:
			img.set_pixel(x, y, c)
	img.save_png("res://materials/lighthouse_stripes.png")
	quit()
