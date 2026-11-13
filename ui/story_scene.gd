extends CanvasLayer
## The one scene player: a table of shots (camera from/to, look_from/look_to, dialogue, cues) on
## its own Camera3D with a warm light, the HUD stepped aside and the night clock frozen
## (`GameState.scene_active`). The opening (`opening_cutscene.gd`) subclasses it; the story scenes
## that fire as the night goes on are the `SCENES` table below, triggered by `GameState`
## (`SCENE_TRIGGERS`, flags in `scenes_seen`, once each, saved) and played by `ui/overlay.gd`.
## Holding interact (E / Square, or a finger with touch controls) for 1 s skips to the last shot.
##
## Shot keys (all world space): t, len, from/to, look_from/look_to, fov, black, title, lines
## ([pause, text] in order; a leading dash means the keeper speaks), cue (one sound at 0.5 s) or
## cues ([[seconds, sound], ...]), spawn ([{model, at, yaw, tint, amount}] temporary actors),
## do ([[group, method, [args]], ...] run once on entering the shot), look_call ([group, method]
## returning the point to look at; an optional third item is its argument list), message (big red
## text, with a PS1 jitter), flash (white flash on entering), shake (camera jitter amplitude),
## silence (seconds the sound is cut on entering), sail and track (the boat, opening only).
## A scene is {shots, end_do}; end_do runs when it finishes or is skipped.

signal finished

const IMPACT := preload("res://ui/impact.gd")
const SKIP_HOLD := 1.0
const SKIP_FADE := 0.5
const CHARS_PER_SECOND := 30.0
const LINE_HOLD := 1.6

const SEA := -1.2
const HOUSE_DESK := Vector3(25.25, 1.0, 5.4)

## The scenes that fire during the night (triggers in `GameState.SCENE_TRIGGERS`). Each ends with
## a short black shot so skipping has somewhere to land.
const SCENES := {
	# Tutorials (keeper's dry narration), each ending in a short black shot.
	"tut_lamp": {"shots": [
		{"t": 0.0, "len": 8.0, "from": Vector3(5.0, 2.0, -3.0), "to": Vector3(4.0, 3.0, -5.0),
			"look_from": Vector3(0, 16.4, -12), "look_to": Vector3(0, 16.6, -12),
			"lines": [[0.8, "— A lâmpada não acende com fé. Primeiro, óleo."],
				[0.4, "— Depois, AQUECER e BOMBEAR até temperatura e pressão ficarem no verde."]]},
		{"t": 8.0, "len": 10.0, "from": Vector3(0.0, 18.2, -9.0), "to": Vector3(-0.8, 18.2, -9.0),
			"look_from": Vector3(0, 16.4, -12), "look_to": Vector3(0, 16.4, -12), "cue": "lamp_valve",
			"lines": [[0.6, "— Só no verde se abre a VÁLVULA. Aberta fria, ela afoga."],
				[0.5, "— Acesa, é só dar CORDA. Quando o pulso da catraca bater."],
				[0.5, "— Senão, ela morre. E o mar escuta."]]},
		{"t": 18.0, "len": 0.6, "black": true},
	]},
	"tut_generator": {"shots": [
		{"t": 0.0, "len": 9.0, "from": Vector3(-16.5, 1.8, 18.5), "to": Vector3(-18.0, 1.6, 17.5),
			"look_from": Vector3(-20.4, 0.9, 14.7), "look_to": Vector3(-20.4, 0.9, 14.7), "cue": "gust",
			"lines": [[0.8, "— O gerador. Combustível no tanque, depois as válvulas, A até D."],
				[0.4, "— Na ordem do livro de registros. Aperte J. O rádio também sabe."]]},
		{"t": 9.0, "len": 10.0, "from": Vector3(-18.0, 1.6, 17.5), "to": Vector3(-19.0, 1.5, 17.0),
			"look_from": Vector3(-20.4, 1.0, 14.7), "look_to": Vector3(-20.4, 1.2, 14.7),
			"lines": [[0.6, "— Ligado, vá ao quadro de força. Rádio, luz, motor da lanterna."],
				[0.5, "— Ele aguenta dois circuitos. Dois."],
				[0.5, "— O terceiro ele cobra de você."]]},
		{"t": 19.0, "len": 0.6, "black": true},
	]},
	"tut_oil_factory": {"shots": [
		{"t": 0.0, "len": 9.0, "from": Vector3(-9.5, 1.8, 27.0), "to": Vector3(-10.5, 1.7, 25.5),
			"look_from": Vector3(-12.0, 1.0, 21.5), "look_to": Vector3(-12.0, 1.0, 21.5),
			"lines": [[0.8, "— A fábrica de óleo. Madeira, gordura ou algas."],
				[0.4, "— Três insumos para cada lata."]]},
		{"t": 9.0, "len": 8.0, "from": Vector3(-10.5, 1.7, 25.5), "to": Vector3(-11.3, 1.6, 24.3),
			"look_from": Vector3(-12.0, 1.1, 21.5), "look_to": Vector3(-12.0, 1.2, 21.5), "cue": "clunk",
			"lines": [[0.6, "— Ela demora. Vá cuidar do que é seu."],
				[0.5, "— Volte ao console e recolha as latas prontas."]]},
		{"t": 17.0, "len": 0.6, "black": true},
	]},
	"tut_fuel_factory": {"shots": [
		{"t": 0.0, "len": 9.0, "from": Vector3(-6.0, 1.8, 27.0), "to": Vector3(-7.0, 1.7, 25.5),
			"look_from": Vector3(-8.5, 1.0, 21.5), "look_to": Vector3(-8.5, 1.0, 21.5),
			"lines": [[0.8, "— A do combustível. Madeira, carvão ou restos."],
				[0.4, "— Três insumos, uma lata. Sempre três."]]},
		{"t": 9.0, "len": 8.0, "from": Vector3(-7.0, 1.7, 25.5), "to": Vector3(-7.8, 1.6, 24.3),
			"look_from": Vector3(-8.5, 1.1, 21.5), "look_to": Vector3(-8.5, 1.2, 21.5), "cue": "clunk",
			"lines": [[0.6, "— É mais lenta que a de óleo. O gerador não espera por ela."],
				[0.5, "— Recolha no console quando acabar."]]},
		{"t": 17.0, "len": 0.6, "black": true},
	]},
	# Stations of the expansion (positions: Station_* markers in world/expansion.tscn, ground ~ y 0).
	"tut_fishing": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(7.0, 1.8, -48.0), "to": Vector3(7.5, 1.7, -50.0),
			"look_from": Vector3(7.0, 0.8, -55.0), "look_to": Vector3(7.0, 0.6, -55.0), "cue": "splash",
			"lines": [[0.8, "— A armadilha de pesca. Segure até o peixe subir."],
				[0.4, "— Duas vezes por noite. O mar não é generoso."]]},
		{"t": 7.0, "len": 7.0, "from": Vector3(7.5, 1.7, -50.0), "to": Vector3(8.2, 1.6, -51.2),
			"look_from": Vector3(6.0, 0.2, -60.0), "look_to": Vector3(4.0, 0.2, -66.0),
			"lines": [[0.6, "— Não olhe a água por muito tempo."],
				[0.6, "— Às vezes ela olha de volta."]]},
		{"t": 14.0, "len": 0.6, "black": true},
	]},
	"tut_workshop": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(-27.0, 1.8, 14.0), "to": Vector3(-27.0, 1.7, 12.3),
			"look_from": Vector3(-27.0, 1.0, 8.0), "look_to": Vector3(-27.0, 1.0, 8.0), "cue": "clunk",
			"lines": [[0.8, "— A oficina. Sucata e carvão viram munição."],
				[0.4, "— Também pilha. E limpador de lente."]]},
		{"t": 7.0, "len": 7.0, "from": Vector3(-27.0, 1.7, 12.3), "to": Vector3(-26.2, 1.6, 11.2),
			"look_from": Vector3(-27.0, 1.1, 8.0), "look_to": Vector3(-27.0, 1.2, 8.0),
			"lines": [[0.6, "— Cada bala custa o que você ainda não achou."],
				[0.6, "— Gaste com juízo. A noite é longa."]]},
		{"t": 14.0, "len": 0.6, "black": true},
	]},
	"tut_garden": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(22.0, 1.8, 24.0), "to": Vector3(22.0, 1.7, 22.3),
			"look_from": Vector3(22.0, 0.6, 18.0), "look_to": Vector3(22.0, 0.5, 18.0), "cue": "gust",
			"lines": [[0.8, "— A horta. Uma colheita por noite."],
				[0.4, "— Colheu, acabou. Terra não tem pressa."]]},
		{"t": 7.0, "len": 6.0, "from": Vector3(22.0, 1.7, 22.3), "to": Vector3(22.8, 1.6, 21.2),
			"look_from": Vector3(22.0, 0.5, 18.0), "look_to": Vector3(22.0, 0.4, 18.0),
			"lines": [[0.6, "— Come-se o que dá. Mas olhe antes de morder."]]},
		{"t": 13.0, "len": 0.6, "black": true},
	]},
	"tut_watchtower": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(-60.0, 1.8, -12.0), "to": Vector3(-62.0, 1.8, -14.0),
			"look_from": Vector3(-67.0, 5.0, -19.0), "look_to": Vector3(-67.0, 6.0, -19.0), "cue": "gust",
			"lines": [[0.8, "— A torre. O binóculo mostra o navio e o rumo."],
				[0.4, "— Mas só com o rádio ligado. Sem energia, só neblina."]]},
		{"t": 7.0, "len": 7.0, "from": Vector3(-62.0, 1.8, -14.0), "to": Vector3(-63.5, 2.0, -15.5),
			"look_from": Vector3(-95.0, 2.0, -40.0), "look_to": Vector3(-100.0, 2.5, -45.0),
			"lines": [[0.6, "— Ver cedo ajuda a decidir."],
				[0.6, "— Nem tudo que acena vem com boa intenção."]]},
		{"t": 14.0, "len": 0.6, "black": true},
	]},
	"tut_fence": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(31.0, 1.8, 13.0), "to": Vector3(30.0, 1.7, 11.5),
			"look_from": Vector3(27.0, 1.0, 7.0), "look_to": Vector3(27.0, 1.0, 7.0), "cue": "clunk",
			"lines": [[0.8, "— A cerca gasta madeira. Reduz a invasão e a atrasa."],
				[0.4, "— Dois níveis. O primeiro é a porta da casa."]]},
		{"t": 7.0, "len": 7.0, "from": Vector3(30.0, 1.7, 11.5), "to": Vector3(29.0, 1.6, 10.5),
			"look_from": Vector3(27.0, 1.2, 7.0), "look_to": Vector3(26.5, 1.4, 7.0),
			"lines": [[0.6, "— Atrasa. Não impede."],
				[0.6, "— O que vem da água sabe esperar."]]},
		{"t": 14.0, "len": 0.6, "black": true},
	]},
	"tut_cave": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(31.0, 1.7, -50.0), "to": Vector3(31.0, 1.6, -52.5),
			"look_from": Vector3(31.0, 1.3, -58.0), "look_to": Vector3(31.0, 1.3, -60.0), "cue": "gust",
			"lines": [[0.8, "— A gruta. Tem carvão, se o senhor aguentar o escuro."],
				[0.4, "— Leve a lanterna. E pilha de sobra."]]},
		{"t": 7.0, "len": 8.0, "from": Vector3(31.0, 1.6, -52.5), "to": Vector3(31.0, 1.5, -55.0),
			"look_from": Vector3(31.0, 1.3, -65.5), "look_to": Vector3(31.0, 1.2, -66.0), "cue": "hull_knock",
			"lines": [[0.8, "— Algo vive lá dentro."],
				[0.8, "— Eu ouvi respirar. Não de pulmão."]]},
		{"t": 15.0, "len": 0.6, "black": true},
	]},
	# First time inside the house: the radio voice teaches the radio and the logbook.
	"house": {"shots": [
		{"t": 0.0, "len": 15.0, "from": Vector3(28.6, 1.55, 8.9), "to": Vector3(27.2, 1.5, 7.6),
			"look_from": HOUSE_DESK, "look_to": HOUSE_DESK, "cue": "static",
			"lines": [[0.6, "Rádio: Sete, aqui o barqueiro. Ouviu?"],
				[0.5, "Ligue o gerador e o rádio chama. Gire a sintonia até o sinal ficar claro."],
				[0.5, "Ouça a carga e compare com o livro de registros."],
				[0.5, "Igual, autorize. Diferente, recuse. É a regra."]]},
		{"t": 15.0, "len": 8.0, "from": Vector3(27.2, 1.5, 7.6), "to": Vector3(26.4, 1.4, 6.6),
			"look_from": Vector3(25.5, 0.9, 5.6), "look_to": Vector3(25.5, 0.9, 5.6),
			"lines": [[0.4, "O livro fica na mesa. Aperte J para ler."], [0.5, "Tudo que o senhor achar, ele anota."]]},
		{"t": 23.0, "len": 0.6, "black": true},
	]},
	# First time the lamp burns: the beam sweeps the sea and the ship at the horizon answers.
	"lamp": {"shots": [
		{"t": 0.0, "len": 6.0, "from": Vector3(7.0, 2.0, 2.0), "to": Vector3(5.0, 3.0, 4.0),
			"look_from": Vector3(0, 17.0, -12), "look_to": Vector3(0, 17.5, -12), "cue": "lamp_valve"},
		{"t": 6.0, "len": 11.0, "from": Vector3(0.0, 18.2, -9.0), "to": Vector3(-1.0, 18.2, -9.0),
			"look_from": Vector3(-26, 8, 95), "look_to": Vector3(-30, 6, 108),
			"do": [["horizon_ship", "answer", [6.0]]], "cue": "boat_bell",
			"lines": [[3.0, "Lá longe, o cargueiro piscou as luzes."], [0.4, "— Alguém viu."]]},
		{"t": 17.0, "len": 0.6, "black": true},
	]},
	# 23:45: the Sineiro rings three times, nobody there.
	"bell": {"shots": [
		{"t": 0.0, "len": 11.0, "from": Vector3(2.5, 1.6, 41.0), "to": Vector3(2.0, 1.5, 43.5),
			"look_from": Vector3(0.0, 1.0, 52.0), "look_to": Vector3(0.0, 1.3, 52.0),
			"cues": [[2.5, "bell"], [4.8, "bell"], [7.1, "bell"]],
			"lines": [[3.0, "Um sino toca no píer. Uma vez, duas, três."], [4.2, "Ninguém por lá."]]},
		{"t": 11.0, "len": 0.6, "black": true},
	]},
	# 00:00: the first Lavado standing on the beach, back turned.
	"lavado": {"shots": [
		{"t": 0.0, "len": 9.0, "from": Vector3(0.0, 2.0, 23.0), "to": Vector3(0.5, 1.8, 26.0),
			"look_from": Vector3(-9.0, 1.4, 35.0), "look_to": Vector3(-9.0, 1.4, 35.0),
			"spawn": [{"model": "Character_Killer_01", "at": Vector3(-9.0, 0.0, 35.0), "yaw": 0.0,
				"tint": Color(0.25, 0.4, 0.7), "amount": 0.85}],
			"cue": "gust", "lines": [[2.0, "Alguém de pé na praia, de costas para a ilha."], [0.5, "Vindo do mar."]]},
		{"t": 9.0, "len": 0.6, "black": true},
	]},
	# The Aurora authorized while lying: the dark ship comes in, the Captain stares, the screen says it.
	"aurora": {"shots": [
		{"t": 0.0, "len": 7.0, "from": Vector3(1.0, 1.8, 50.0), "to": Vector3(1.5, 1.8, 52.0),
			"look_from": Vector3(8.0, 2.5, 64.0), "look_to": Vector3(9.0, 2.5, 66.0),
			"do": [["ship_traffic", "haunt", ["Aurora", true]]], "cues": [[0.5, "splash"], [3.5, "splash"]],
			"lines": [[2.0, "O Aurora chega ao píer. Escuro."], [0.5, "As luzes se apagam, uma a uma."]]},
		{"t": 7.0, "len": 8.0, "from": Vector3(3.0, 2.0, 57.0), "to": Vector3(5.0, 2.2, 59.5), "fov": 45.0,
			"look_from": Vector3(9, 3, 68), "look_to": Vector3(9, 3, 68), "look_call": ["ship_traffic", "captain_position", ["Aurora"]],
			"cues": [[2.0, "boat_bell"]], "lines": [[1.5, "No convés, a Capitã. Ela olha para você."]]},
		{"t": 15.0, "len": 6.0, "from": Vector3(5.0, 2.2, 59.5), "to": Vector3(5.5, 2.2, 60.5), "fov": 40.0,
			"look_from": Vector3(9, 3, 68), "look_to": Vector3(9, 3, 68), "look_call": ["ship_traffic", "captain_position", ["Aurora"]],
			"flash": true, "shake": 0.02, "silence": 1.4,
			"message": "VOCÊ NÃO DEVERIA TER AUTORIZADO...\nO Aurora nunca foi o Aurora."},
		{"t": 21.0, "len": 0.6, "black": true},
	]},
	# Dawn, "Continuar": the boatman's boat comes alongside the pier to take the keeper to rest (happy end).
	"dawn": {"shots": [
		{"t": 0.0, "len": 8.0, "from": Vector3(0.5, 1.8, 43.0), "to": Vector3(1.8, 1.8, 44.5),
			"look_from": Vector3(3.3, 0.2, 47.5), "look_to": Vector3(3.3, 0.2, 47.5), "cues": [[0.5, "boat_bell"], [3.0, "splash"]],
			"lines": [[1.0, "O sol sobe. Um barco pequeno corta a neblina até o píer."], [0.5, "O barqueiro, de pé, acena."]]},
		{"t": 8.0, "len": 9.0, "from": Vector3(2.0, 1.6, 44.5), "to": Vector3(2.6, 1.6, 45.8), "fov": 50.0,
			"look_from": Vector3(3.3, 0.5, 47.5), "look_to": Vector3(3.3, 0.5, 47.5),
			"lines": [[1.0, "Barqueiro: Sete! Passou a noite em pé, hein?"], [0.6, "Barqueiro: Sobe. Hoje o senhor dorme."], [0.8, "— O farol aguenta até a noite."]]},
		{"t": 17.0, "len": 0.8, "black": true},
	]},
	# 03:05: the Captain on the Casco, a glance.
	"captain": {"shots": [
		{"t": 0.0, "len": 9.0, "from": Vector3(-18.0, 3.0, 20.0), "to": Vector3(-20.0, 3.2, 21.5), "fov": 40.0,
			"look_from": Vector3(-40, 5, 24), "look_to": Vector3(-40, 5, 24), "look_call": ["santa_aurora", "captain_position"],
			"do": [["santa_aurora", "force_captain", [true]]], "cue": "hull_knock",
			"lines": [[2.0, "No convés do Casco, alguém de uniforme."], [0.6, "Olhando para o farol."]]},
		{"t": 9.0, "len": 0.6, "black": true},
	], "end_do": [["santa_aurora", "force_captain", [false]]]},
}

var scene_id := ""
var data := {} ## {shots, end_do}

var _shots: Array = []
var _t := 0.0
var _shot := -1
var _done := false
var _skip_hold := 0.0
var _skip_hint := 4.0
var _skipping := -1.0
var _cues_played := {}
var _lines: Array = []
var _line := ""
var _line_shown := 0.0
var _line_hold := 0.0
var _next_line_at := 0.0
var _player: Node3D
var _spawned: Array[Node3D] = []
var _entered := {} ## shot index -> true once its spawns and `do` ran
var _camera: Camera3D
var _light: OmniLight3D
var _black: ColorRect
var _title: Label
var _alert: Label
var _flash: ColorRect
var _flash_left := 0.0
var _muted := false
var _jitter := 0.0
var _dialog_frame: PanelContainer
var _dialog: Label
var _hint: Label
var _ring: SkipRing


func _ready() -> void:
	layer = 15
	data = _scene_data()
	_shots = data.shots
	GameState.scene_active = true
	_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player:
		_player.locked = true
	GameState.set_panel_open(self, true)
	_build_ui()
	_camera = Camera3D.new()
	_camera.fov = 60.0
	_camera.far = 200.0
	get_parent().add_child(_camera)
	_camera.current = true
	# Warm light riding with the camera: the night look alone leaves the shots near black.
	_light = OmniLight3D.new()
	_light.omni_range = 40.0
	_light.light_energy = 1.6
	_light.light_color = Color(1.0, 0.72, 0.5)
	_camera.add_child(_light)
	_begin()
	_apply(0.0)


## The shots of this scene. Subclasses (the opening) bring their own table.
func _scene_data() -> Dictionary:
	return SCENES[scene_id]


## Hooks for subclasses: stage the cast before the first shot, undo it at the end, and know who
## speaks (`on` while the line is typed and held).
func _begin() -> void:
	pass


func _end() -> void:
	pass


func _speaking(_text: String, _on: bool) -> void:
	pass


func _shot_extra(_shot: Dictionary, _k: float) -> void:
	pass


func _process(delta: float) -> void:
	# A long hitch (the scene just loaded) must not eat the first shots.
	advance(minf(delta, 0.1))


## Steps the cutscene by `delta` seconds (tests drive it directly).
func advance(delta: float) -> void:
	if _done:
		return
	_update_skip(delta)
	_t += delta
	if _skipping >= 0.0:
		_skipping -= delta
		_black.modulate.a = 1.0
		if _skipping <= 0.0:
			_skipping = -1.0
			_t = _shots[-1].t
			_shot = -1
			_lines.clear()
			if not _line.is_empty():
				_speaking(_line, false)
			_line = ""
	if _t >= float(_shots[-1].t) + float(_shots[-1].len):
		_finish()
		return
	_apply(delta)


func skip() -> void:
	if _skipping < 0.0 and _t < float(_shots[-1].t):
		_skipping = SKIP_FADE


func _apply(delta: float) -> void:
	var index := _shot_at(_t)
	var shot: Dictionary = _shots[index]
	var local := _t - float(shot.t)
	var k := clampf(local / float(shot.len), 0.0, 1.0)
	if index != _shot:
		_shot = index
		_lines = shot.get("lines", []).duplicate()
		_next_line_at = _lines[0][0] if not _lines.is_empty() else INF
		if not _entered.has(index):
			_entered[index] = true
			_enter(shot)
	_place_camera(shot, k)
	_shot_extra(shot, k)
	var cues: Array = shot.get("cues", [[0.5, shot.cue]] if shot.has("cue") else [])
	for n in cues.size():
		var key := "%d:%d" % [index, n]
		if local >= float(cues[n][0]) and not _cues_played.has(key):
			_cues_played[key] = true
			GameState.play(cues[n][1], _camera.global_position)
	_update_titles(shot, local)
	_update_alert(shot, local, delta)
	_update_dialog(delta, local)
	if _skipping < 0.0:
		_black.modulate.a = 1.0 if shot.get("black", false) else 0.0


func _enter(shot: Dictionary) -> void:
	for spec: Dictionary in shot.get("spawn", []):
		var actor := Actors.character(spec.model, spec.get("tint", Color.WHITE), spec.get("amount", 0.0))
		get_parent().add_child(actor)
		actor.global_position = _ground(spec.at)
		actor.rotation.y = spec.get("yaw", 0.0)
		_spawned.append(actor)
	_run(shot.get("do", []))
	if shot.get("flash", false):
		_flash_left = 1.0
	if shot.has("silence"):
		_muted = true
		AudioServer.set_bus_mute(0, true)
		get_tree().create_timer(float(shot.silence), true, false, true).timeout.connect(_unmute)


func _unmute() -> void:
	if _muted:
		_muted = false
		AudioServer.set_bus_mute(0, false)


func _run(calls: Array) -> void:
	for entry: Array in calls:
		var node := get_tree().get_first_node_in_group(entry[0])
		if node and node.has_method(entry[1]):
			node.callv(entry[1], entry[2])


## Drops a point onto the world (layer 1); stays at its height over water.
func _ground(point: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(Vector3(point.x, 30.0, point.z), Vector3(point.x, -5.0, point.z), 1)
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(query)
	return point if hit.is_empty() else hit.position


func _shot_at(time: float) -> int:
	for i in range(_shots.size() - 1, -1, -1):
		if time >= _shots[i].t:
			return i
	return 0


func _place_camera(shot: Dictionary, k: float) -> void:
	if shot.get("black", false):
		return
	var eased := smoothstep(0.0, 1.0, k)
	_camera.global_position = (shot.from as Vector3).lerp(shot.to, eased)
	_camera.fov = shot.get("fov", 60.0)
	var target := (shot.look_from as Vector3).lerp(shot.look_to, eased)
	if shot.has("look_call"):
		var node := get_tree().get_first_node_in_group(shot.look_call[0])
		if node and node.has_method(shot.look_call[1]):
			target = node.callv(shot.look_call[1], shot.look_call[2] if shot.look_call.size() > 2 else [])
	_look(shot, target)


## Aims the camera; the opening overrides it to follow the boat.
func _look(_shot: Dictionary, target: Vector3) -> void:
	_camera.look_at(target)


## The red message: fades in, jitters a pixel or two (PS1 vertex snap) and the flash decays.
func _update_alert(shot: Dictionary, local: float, delta: float) -> void:
	_flash_left = maxf(_flash_left - delta * 2.0, 0.0)
	_flash.color.a = IMPACT.step_alpha(_flash_left) * 0.7 # same 3 hard steps as the in-game impact
	var amplitude: float = shot.get("shake", 0.0)
	_camera.h_offset = randf_range(-amplitude, amplitude) * 4.0
	_camera.v_offset = randf_range(-amplitude, amplitude) * 4.0
	_alert.visible = shot.has("message")
	if not _alert.visible:
		return
	_alert.text = shot.message
	_alert.modulate.a = clampf(local / 0.4, 0.0, 1.0)
	_jitter -= delta
	if _jitter <= 0.0:
		_jitter = 0.08
		_alert.position = Vector2(randi_range(-1, 1), randi_range(-1, 1))


func _update_titles(shot: Dictionary, local: float) -> void:
	if not shot.has("title"):
		_title.visible = false
		return
	_title.visible = true
	_title.text = shot.title
	var length: float = shot.len
	var fade := minf(local / 0.8, (length - local) / 0.8)
	_title.modulate.a = clampf(fade, 0.0, 1.0)


func _update_dialog(delta: float, local: float) -> void:
	if _line.is_empty():
		if not _lines.is_empty() and local >= _next_line_at:
			var entry: Array = _lines.pop_front()
			_line = entry[1]
			_line_shown = 0.0
			_line_hold = LINE_HOLD
			_speaking(_line, true)
		else:
			_dialog_frame.visible = false
			return
	_dialog_frame.visible = true
	if _line_shown < _line.length():
		_line_shown = minf(_line_shown + CHARS_PER_SECOND * delta, _line.length())
	else:
		_line_hold -= delta
		if _line_hold <= 0.0:
			_speaking(_line, false)
			_line = ""
			if not _lines.is_empty():
				_next_line_at = local + float(_lines[0][0])
			return
	_dialog.text = _line.substr(0, int(_line_shown))


func _update_skip(delta: float) -> void:
	var touching := TouchControls.enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if Input.is_action_pressed("interact") or touching:
		_skip_hold += delta
		if _skip_hold >= SKIP_HOLD:
			skip()
	else:
		_skip_hold = 0.0
	_skip_hint = maxf(_skip_hint - delta, 0.0)
	_hint.visible = _skip_hint > 0.0 or _skip_hold > 0.0
	_ring.ratio = clampf(_skip_hold / SKIP_HOLD, 0.0, 1.0)
	_ring.visible = _skip_hold > 0.0
	_ring.queue_redraw()


func _input(event: InputEvent) -> void:
	if _done:
		return
	var pressed := (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed()
	if pressed and not event.is_action("interact") and not event.is_action("pause"):
		_skip_hint = 2.0


func _finish() -> void:
	if _done:
		return
	_done = true
	_unmute()
	_end()
	_run(data.get("end_do", []))
	for actor in _spawned:
		actor.queue_free()
	if _player:
		_player.locked = false
		var eyes: Camera3D = _player.get_node("Head/Camera3D")
		eyes.current = true
	GameState.scene_active = false
	GameState.set_panel_open(self, false)
	_camera.queue_free()
	finished.emit()
	queue_free()


func _exit_tree() -> void:
	_unmute()
	if not _done:
		GameState.scene_active = false


# ---- Building

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_black = ColorRect.new()
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_black)
	_title = UiKit.heading("")
	_title.set_anchors_preset(Control.PRESET_FULL_RECT)
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	root.add_child(_title)
	_alert = UiKit.label("", 0, UiKit.BLOOD.lightened(0.15))
	_alert.add_theme_font_size_override("font_size", UiKit.HEADING_SIZE)
	_alert.set_anchors_preset(Control.PRESET_FULL_RECT)
	_alert.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_alert.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_alert.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_alert.add_theme_constant_override("line_spacing", 4)
	_alert.visible = false
	root.add_child(_alert)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_flash)
	_dialog_frame = PanelContainer.new()
	_dialog_frame.add_theme_stylebox_override("panel", UiKit.bar())
	var width := get_viewport().get_visible_rect().size.x
	_dialog_frame.position = Vector2((width - 260.0) / 2.0, 196)
	_dialog_frame.custom_minimum_size = Vector2(260, 30)
	_dialog_frame.visible = false
	root.add_child(_dialog_frame)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(250, 24)
	_dialog_frame.add_child(holder)
	_dialog = UiKit.label("", 250)
	_dialog.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialog.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialog.size = Vector2(250, 24)
	holder.add_child(_dialog)
	_hint = UiKit.label("Segure o toque para pular" if TouchControls.enabled else "Segure E / Quadrado para pular", 0, Color(0.8, 0.82, 0.75, 0.8))
	_hint.position = Vector2(width - 150.0, 4)
	_hint.visible = false
	root.add_child(_hint)
	_ring = SkipRing.new()
	_ring.position = Vector2(width - 20.0, 6)
	_ring.size = Vector2(12, 12)
	_ring.visible = false
	root.add_child(_ring)


## The skip progress ring, like the HUD's hold bar but round.
class SkipRing extends Control:
	var ratio := 0.0

	func _draw() -> void:
		var center := size / 2.0
		draw_arc(center, 5.0, 0.0, TAU, 16, Color(0, 0, 0, 0.6), 2.0)
		if ratio > 0.0:
			draw_arc(center, 5.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 16, UiKit.BRASS, 2.0)
