extends CanvasLayer
## HUD panel for radio calls: what is coming in, what the ship claims and how the last ones went.

var _text: Label


func _ready() -> void:
	layer = 9
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.style(Color(0, 0, 0, 0.5), Color(0.3, 0.45, 0.4)))
	panel.position = Vector2(196, 26)
	panel.custom_minimum_size = Vector2(120, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text = UiKit.label("", 112, Color(0.8, 0.95, 0.9))
	panel.add_child(_text)
	add_child(panel)


func _process(_delta: float) -> void:
	var lines: Array[String] = ["CHAMADOS"]
	var call: Dictionary = GameState.active_call
	if call.is_empty():
		lines.append("Rádio sem energia." if not GameState.powered("radio") else "Sem chamadas. Aguardando.")
	elif call.status == "incoming":
		lines.append("(!) Chamada entrando. Sintonize o rádio. %d s" % ceili(call.left))
	else:
		lines.append("%s pede atracação. Carga declarada: %s. Compare com o registro. %d s" % [call.call, call.claim, ceili(call.left)])
	for entry in GameState.call_log.slice(0, 3):
		lines.append(entry)
	_text.text = "\n".join(lines)
