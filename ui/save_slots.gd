class_name SaveSlots
extends PanelContainer
## Slot screen for the title menu, built in code. "new" mode lists slots 1-3 (empty ones start
## a game, occupied ones ask before overwriting); "load" mode lists only occupied slots. Each
## row can be deleted after a confirmation. Works with mouse, keys and the PS4 pad (focus moves
## with the d-pad/stick, X accepts, Circle goes back).

signal chosen(slot: int, data: Dictionary)
signal closed

const SAVE := preload("res://save_game.gd")

var mode := "new"

var _box: VBoxContainer
var _rows: VBoxContainer
var _confirm: VBoxContainer
var _question: Label
var _yes: Button
var _no: Button
var _pending := Callable()


func _ready() -> void:
	custom_minimum_size = Vector2(250, 0)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	_confirm = VBoxContainer.new()
	_confirm.add_theme_constant_override("separation", 4)
	_question = UiKit.label("", 230)
	_question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm.add_child(_question)
	var answers := HBoxContainer.new()
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	answers.add_theme_constant_override("separation", 10)
	_yes = UiKit.button("Sim", _on_yes)
	_no = UiKit.button("Não", _close_confirm)
	answers.add_child(_yes)
	answers.add_child(_no)
	_confirm.add_child(answers)
	_confirm.visible = false


func open(new_mode: String) -> void:
	mode = new_mode
	visible = true
	_rebuild()


## Slot label: night time, real save date, lamp state, or VAZIO.
static func describe(slot: int) -> String:
	if not SAVE.exists(slot):
		return "%d · VAZIO" % slot
	var meta: Dictionary = SAVE.meta(slot)
	var saved: String = meta.get("saved_at", "")
	var when := saved
	if saved.length() >= 16:
		when = "%s/%s %s" % [saved.substr(8, 2), saved.substr(5, 2), saved.substr(11, 5)]
	var night: String = "NOITE ENCERRADA" if meta.get("finished", false) else "%s · lâmpada %s" % [meta.get("clock", "--:--"), str(meta.get("lamp", "?")).to_lower()]
	return "%d · %s · %s" % [slot, night, when]


func _rebuild() -> void:
	for child in _box.get_children():
		_box.remove_child(child)
		if child != _rows and child != _confirm:
			child.queue_free()
	for child in _rows.get_children():
		child.queue_free()
	_box.add_child(UiKit.heading("NOVO JOGO" if mode == "new" else "CONTINUAR"))
	_box.add_child(HSeparator.new())
	_box.add_child(_rows)
	var first: Button = null
	for slot in range(1, SAVE.SLOTS + 1):
		var used := SAVE.exists(slot)
		if mode == "load" and not used:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var pick := UiKit.button(describe(slot), _on_pick.bind(slot))
		pick.custom_minimum_size.x = 196
		pick.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(pick)
		var erase := UiKit.button("Apagar", _on_delete.bind(slot))
		erase.disabled = not used
		row.add_child(erase)
		_rows.add_child(row)
		if first == null:
			first = pick
	if first == null:
		_rows.add_child(UiKit.label("Nenhum jogo salvo."))
	_box.add_child(_confirm)
	var back := UiKit.button("Voltar", _on_back)
	_box.add_child(back)
	_confirm.visible = false
	(first if first else back).grab_focus.call_deferred()


func _on_pick(slot: int) -> void:
	if mode == "load":
		chosen.emit(slot, SAVE.read(slot))
	elif SAVE.exists(slot):
		_ask("Sobrescrever o slot %d?" % slot, _start_new.bind(slot))
	else:
		_start_new(slot)


func _start_new(slot: int) -> void:
	SAVE.delete(slot)
	chosen.emit(slot, {})


func _on_delete(slot: int) -> void:
	_ask("Apagar o slot %d? Não dá para desfazer." % slot, _delete_now.bind(slot))


func _delete_now(slot: int) -> void:
	SAVE.delete(slot)
	_rebuild()


func _ask(question: String, action: Callable) -> void:
	_question.text = question
	_pending = action
	_rows.visible = false
	_confirm.visible = true
	_no.grab_focus.call_deferred()


func _on_yes() -> void:
	var action := _pending
	_close_confirm()
	if action.is_valid():
		action.call()


func _close_confirm() -> void:
	_pending = Callable()
	_confirm.visible = false
	_rows.visible = true
	_rebuild()


func _on_back() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _confirm.visible:
			_close_confirm()
		else:
			_on_back()
		get_viewport().set_input_as_handled()
