extends Marker3D
## Radio desk: tune the call in, compare the ship's claim with the register, then decide.
## Some ships lie about their cargo, more of them as the night wears on, and letting
## a ship dock while the lighthouse is dark wrecks it.

const FREQS := [88.1, 91.5, 94.3, 97.7, 101.2]
const CARGOS := ["café", "carvão", "sal", "lã", "peixe", "tijolos"]
const CALL_TIMEOUT := 45.0

var _freq := 0
var _call := {}
var _contact := false
var _until_next := 20.0
var _count := 0
var _queue: Array = []
var _tune: Interactable
var _authorize: Interactable
var _refuse: Interactable
var _logbook: Interactable


func _ready() -> void:
	_tune = _add("Tune", -0.6, "", 0.0)
	_authorize = _add("Authorize", -0.2, "Autorizar atracação", 1.2)
	_refuse = _add("Refuse", 0.2, "Recusar a chamada", 0.0)
	_logbook = _add("Logbook", 0.6, "Ler o livro de registros", 0.0, 0.2)
	_tune.interacted.connect(_on_tune)
	_authorize.interacted.connect(func(_by: Node) -> void: _resolve(true))
	_refuse.interacted.connect(func(_by: Node) -> void: _resolve(false))
	_logbook.interacted.connect(_on_logbook)


func _process(delta: float) -> void:
	var on := GameState.powered("radio")
	_tune.prompt = "Sintonizar (%.1f MHz)" % FREQS[_freq] if on else "Rádio sem energia"
	_authorize.enabled = on and _contact
	_refuse.enabled = on and _contact
	if not on:
		return
	if _call.is_empty():
		_until_next -= delta
		if _until_next <= 0.0:
			_spawn_call()
	else:
		_call.left -= delta
		GameState.active_call = _call
		if _call.left <= 0.0:
			_lose("A chamada se perdeu na estática.", "- %s: perdida" % _call.call)


func _add(node_name: String, x: float, prompt_text: String, hold: float, z := 0.5) -> Interactable:
	var item := Interactable.create(prompt_text, hold, 0.17)
	item.name = node_name
	item.position = Vector3(x, 0.0, z)
	add_child(item)
	return item


## Every third ship lies early in the night, every second one after midnight.
func _anomaly_every() -> int:
	return 2 if GameState.progress() > 0.5 else 3


func _spawn_call() -> void:
	if _queue.is_empty():
		_queue = GameState.SHIPS.duplicate()
		_queue.shuffle()
	var ship: Dictionary = _queue.pop_back()
	_count += 1
	var claim: String = ship.register
	if _count % _anomaly_every() == 0:
		var others := CARGOS.duplicate()
		others.erase(ship.register)
		claim = others.pick_random()
	_call = {"call": ship.call, "register": ship.register, "claim": claim, "freq": randi() % FREQS.size(), "status": "incoming", "left": CALL_TIMEOUT}
	_until_next = randf_range(60.0, 90.0) * (1.0 - 0.45 * GameState.progress())
	GameState.active_call = _call
	GameState.play("ring", global_position)
	GameState.say("Rádio: há uma chamada na linha. Sintonize.")
	_check_contact()


func _on_tune(_by: Node) -> void:
	if not GameState.powered("radio"):
		GameState.say("O rádio está sem energia. Ligue o disjuntor.")
		return
	_freq = (_freq + 1) % FREQS.size()
	GameState.play("static", global_position)
	if not _check_contact():
		GameState.say("Estática em %.1f MHz." % FREQS[_freq])


func _check_contact() -> bool:
	_contact = not _call.is_empty() and _freq == _call.freq
	if _contact:
		_call.status = "contact"
		GameState.say("\"Aqui é o %s, pedimos atracação. Carga: %s.\"" % [_call.call, _call.claim])
	elif not _call.is_empty():
		_call.status = "incoming"
	return _contact


func _resolve(accept: bool) -> void:
	var liar: bool = _call.claim != _call.register
	var ship: String = _call.call
	_end_call()
	if accept and not GameState.lamp_lit:
		_fail("Sem a luz do farol o %s não achou o canal e encalhou." % ship, "- %s: encalhou no escuro" % ship)
	elif accept and liar:
		_fail("O %s atracou. O registro dizia outra carga, e a tripulação nunca desceu." % ship, "- %s: carga falsa" % ship)
	elif accept:
		_succeed("O %s atracou em segurança." % ship, "+ %s: atracou" % ship)
	elif liar:
		_succeed("Você recusou o %s. A voz no rádio se calou." % ship, "+ %s: recusado" % ship)
	else:
		_fail("O %s seguiu viagem sem ajuda." % ship, "- %s: recusado sem motivo" % ship)


func _lose(message: String, log_entry: String) -> void:
	_end_call()
	_fail(message, log_entry)


func _succeed(message: String, log_entry: String) -> void:
	GameState.ships_saved += 1
	GameState.log_call(log_entry)
	GameState.play("bell", global_position)
	GameState.say(message)


func _fail(message: String, log_entry: String) -> void:
	GameState.ships_lost += 1
	GameState.log_call(log_entry)
	GameState.play("horn")
	GameState.say(message)


func _end_call() -> void:
	_call = {}
	_contact = false
	GameState.active_call = {}


func _on_logbook(_by: Node) -> void:
	GameState.book_requested.emit()
