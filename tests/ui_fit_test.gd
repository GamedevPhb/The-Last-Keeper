extends SceneTree
## Headless test: every visible Control of every panel/menu fits inside the viewport at 320x240 (4:3)
## and 427x240 (16:9), or sits inside a ScrollContainer. Lists what overflows and exits 1.
## Run: godot-4 --headless --path . --script res://tests/ui_fit_test.gd

const SIZES: Array[Vector2i] = [Vector2i(320, 240), Vector2i(427, 240), Vector2i(384, 240)]

var _failures := 0
var _frame := 0
var _size_index := 0
var _step := 0
var _node: Node
var _wait := 0


func _check_fit(label: String) -> void:
	var view := Rect2(Vector2.ZERO, Vector2(root.size))
	var bad := 0
	for control: Node in root.find_children("*", "Control", true, false):
		var c := control as Control
		if not c.is_visible_in_tree() or _in_scroll(c):
			continue
		if c.modulate.a <= 0.0 or c.size.x <= 0 or c.size.y <= 0:
			continue
		var rect := c.get_global_rect()
		if rect.position.x < view.position.x - 0.01 or rect.position.y < view.position.y - 0.01 \
				or rect.end.x > view.end.x + 0.01 or rect.end.y > view.end.y + 0.01:
			bad += 1
			if bad <= 6:
				printerr("  OVERFLOW [%s @%s] %s (%s) rect=%s" % [label, view.size, c.get_path(), c.get_class(), rect])
	if bad > 0:
		_failures += 1
		printerr("FAIL: %s @%s: %d controls outside the viewport" % [label, view.size, bad])


func _in_scroll(c: Control) -> bool:
	var p := c.get_parent()
	while p:
		if p is ScrollContainer:
			return true
		p = p.get_parent()
	return false


func _clear() -> void:
	if _node:
		_node.queue_free()
		_node = null


func _process(_delta: float) -> bool:
	_frame += 1
	if _wait > 0:
		_wait -= 1
		return false
	var state := root.get_node("GameState")
	if _step == 0:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		root.size = SIZES[_size_index]
		state.reset()
		state.pending_load = {}
		state.play_intro = false
		_node = load("res://main.tscn").instantiate()
		root.add_child(_node)
		_step = 1
		_wait = 4
		return false
	var main := _node
	var overlay: Node = main.get_node_or_null("Overlay") if main else null
	match _step:
		1:
			state.begin_play()
			_check_fit("hud")
			overlay.open_pause()
			_next()
		2:
			_check_fit("pausa")
			overlay._pause.get_node("Center/Panel/Box").get_child(4).pressed.emit()
			overlay._controls.visible = true
			_next()
		3:
			_check_fit("pausa+controles")
			overlay._open_settings()
			_next()
		4:
			_check_fit("opcoes")
			overlay._close_settings()
			overlay.resume()
			overlay.open_book()
			for i in 9:
				overlay._turn(1 if i > 0 else 0)
				_check_fit("livro %d" % i)
			overlay.close_book()
			state.dead = true
			overlay._show_death("fome")
			overlay._fate.modulate.a = 1.0
			for l: Label in [overlay._fate_title, overlay._fate_text, overlay._fate_book]:
				l.visible_ratio = 1.0
			overlay._fate_buttons.visible = true
			_next()
		5:
			_check_fit("morte")
			state.dead = false
			overlay._fate.visible = false
			overlay._show_ending()
			_next()
		6:
			_check_fit("resumo")
			overlay._ending.visible = false
			overlay._inventory.open()
			_next()
		7:
			_check_fit("inventario")
			overlay._inventory.close()
			state.has_radio = true
			state.radio_docked = false
			overlay._radio.open()
			_next()
		8:
			_check_fit("radio")
			overlay._radio.close()
			var beacon := main.get_node("Island/Lighthouse/Beacon")
			beacon._on_interacted(null)
			_next()
		9:
			_check_fit("console lampada")
			main.get_node("Island/Lighthouse/Beacon")._console.close()
			for n: Node in main.find_children("*", "", true, false):
				var s := n.get_script() as Script
				if s and s.resource_path.ends_with("fuse_box.gd"):
					n._on_interacted(null)
					break
			_next()
		10:
			_check_fit("console disjuntores")
			for n: Node in main.find_children("*", "CanvasLayer", true, false):
				if n.has_method("close") and n.visible and n != overlay:
					n.close()
			root.get_node("Settings").values["touch"] = 1
			root.get_node("Settings").apply()
			overlay._open_settings()
			_next()
		11:
			_check_fit("opcoes (toque)")
			overlay._close_settings()
			overlay.resume()
			_check_fit("hud (toque)")
			root.get_node("Settings").values["touch"] = 0
			root.get_node("Settings").apply()
			_clear()
			state.reset()
			_node = load("res://ui/main_menu.tscn").instantiate()
			root.add_child(_node)
			_next(4)
		12:
			_check_fit("menu principal")
			_node._open_settings()
			_next()
		13:
			_check_fit("menu opcoes")
			_node._close_settings()
			_node._open_slots("new")
			_next()
		14:
			_check_fit("slots novo")
			_node._open_slots("load")
			_next()
		15:
			_check_fit("slots continuar")
			_node._slots._ask("Sobrescrever o slot 1?", func() -> void: pass)
			_next()
		16:
			_check_fit("slots confirmar")
			_clear()
			_size_index += 1
			_step = 0
			_wait = 2
			if _size_index >= SIZES.size():
				if _failures > 0:
					printerr("UI FIT TEST FAILED (%d)" % _failures)
					quit(1)
				else:
					print("UI FIT TEST PASSED")
					quit(0)
	return false


func _next(frames := 3) -> void:
	_step += 1
	_wait = frames
