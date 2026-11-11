extends Marker3D
## Radio desk: tune the call in, compare the ship's claim with the register, then decide.
## Every third ship lies about its cargo, and letting it dock costs the keeper.

const FREQS := [88.1, 91.5, 94.3, 97.7, 101.2]
const CARGOS := ["café", "carvão", "sal", "lã", "peixe", "tijolos"]
const CALL_TIMEOUT := 45.0
const ANOMALY_EVERY := 3
const SHIPS := [
	{"call": "Marlin", "register": "café"},
	{"call": "Aurora", "register": "carvão"},
	{"call": "Gaivota", "register": "sal"},
	{"call": "Tritão", "register": "lã"},
	{"call": "Estrela do Norte", "register": "peixe"},
	{"call": "Ceres", "register": "tijolos"},
]

var _freq := 0
var _call := {}
var _contact := false
var _call_age := 0.0
var _until_next := 20.0
var _count := 0
var _page := 0
var _queue: Array = []
var _tune: Interactable
var _authorize: Interactable
var _refuse: Interactable
var _logbook: Interactable


func _ready() -> void:
	_tune = _add("Tune", -0.6, "", 0.0)
	_authorize = _add("Authorize", -0.2, "Autorizar atracação", 1.2)
	_refuse = _add("Refuse", 0.2, "Recusar a chamada", 0.0)
	_logbook = _add("Logbook", 0.6, "Ler o livro de registros", 0.0)
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
		_call_age += delta
		if _call_age >= CALL_TIMEOUT:
			_lose("A chamada se perdeu na estática.")


func _add(node_name: String, x: float, prompt_text: String, hold: float) -> Interactable:
	var item := Interactable.create(prompt_text, hold, 0.17)
	item.name = node_name
	item.position = Vector3(x, 0.0, 0.5)
	add_child(item)
	return item


func _spawn_call() -> void:
	if _queue.is_empty():
		_queue = SHIPS.duplicate()
		_queue.shuffle()
	var ship: Dictionary = _queue.pop_back()
	_count += 1
	var claim: String = ship.register
	if _count % ANOMALY_EVERY == 0:
		var others := CARGOS.duplicate()
		others.erase(ship.register)
		claim = others.pick_random()
	_call = {"call": ship.call, "register": ship.register, "claim": claim, "freq": randi() % FREQS.size()}
	_call_age = 0.0
	_until_next = randf_range(60.0, 90.0)
	GameState.say("Rádio: há uma chamada na linha. Sintonize.")
	_check_contact()


func _on_tune(_by: Node) -> void:
	if not GameState.powered("radio"):
		GameState.say("O rádio está sem energia. Ligue o disjuntor.")
		return
	_freq = (_freq + 1) % FREQS.size()
	if not _check_contact():
		GameState.say("Estática em %.1f MHz." % FREQS[_freq])


func _check_contact() -> bool:
	_contact = not _call.is_empty() and _freq == _call.freq
	if _contact:
		GameState.say("\"Aqui é o %s, pedimos atracação. Carga: %s.\"" % [_call.call, _call.claim])
	return _contact


func _resolve(accept: bool) -> void:
	var liar: bool = _call.claim != _call.register
	var ship: String = _call.call
	_call = {}
	_contact = false
	if accept and liar:
		GameState.ships_lost += 1
		GameState.say("O %s atracou. O registro dizia outra carga, e a tripulação nunca desceu." % ship)
	elif accept:
		GameState.ships_saved += 1
		GameState.say("O %s atracou em segurança." % ship)
	elif liar:
		GameState.ships_saved += 1
		GameState.say("Você recusou o %s. A voz no rádio se calou." % ship)
	else:
		GameState.ships_lost += 1
		GameState.say("O %s seguiu viagem sem ajuda." % ship)


func _lose(message: String) -> void:
	_call = {}
	_contact = false
	GameState.ships_lost += 1
	GameState.say(message)


func _on_logbook(_by: Node) -> void:
	var pages := ceili(SHIPS.size() / 3.0)
	if _page < pages:
		var entries: Array[String] = []
		for ship: Dictionary in SHIPS.slice(_page * 3, _page * 3 + 3):
			entries.append("%s: %s" % [ship.call, ship.register])
		GameState.say("Registro de cargas. " + "; ".join(entries))
	else:
		var gen := get_tree().get_first_node_in_group("generator")
		GameState.say("Manual do gerador: abrir as válvulas na ordem %s." % gen.valve_order_text())
	_page = (_page + 1) % (pages + 1)
