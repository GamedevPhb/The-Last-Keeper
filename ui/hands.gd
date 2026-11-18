class_name Hands
extends CanvasLayer
## First-person hands (assets/maos/): a 160x120 pixel-art viewmodel shown as a single right hand (HAND_SCALE) at the bottom right of the
## native 320x240 view. Sits on layer 3: above the 3D world, below the HUD (10) and under the
## PsxPost filter (5), so dithering and CRT apply to it. Hidden while a panel, the opening, the
## death/dawn summary or the menu owns the screen, or when "Mostrar mãos" is off.
## The clips follow what is in hand (the selected hotbar slot, `GameState.held_item()`):
## flashlight -> lanterna_idle / andar / correr (lit lens while on), oil or fuel can ->
## segurar_lata / andar_lata / correr_lata, anything else -> idle / andar_vazio / correr_vazio.
## With a weapon drawn (3D viewmodel) this hand mirrors to the left and holds the flashlight if
## the keeper carries one (GDD 4.11), else stays empty.

const FOLDER := "res://assets/maos/"
## name -> [frames, fps, loop]
const CLIPS := {
	"idle": [8, 8.0, true],
	"lanterna_idle": [8, 8.0, true],
	"lanterna_ligar": [5, 10.0, false],
	"lanterna_desligar": [5, 10.0, false],
	"andar": [8, 10.0, true],
	"correr": [8, 12.0, true],
	"andar_vazio": [8, 10.0, true],
	"correr_vazio": [8, 12.0, true],
	"andar_lata": [8, 10.0, true],
	"correr_lata": [8, 12.0, true],
	"pegar": [10, 10.0, false],
	"segurar_lata": [6, 8.0, true],
	"interagir": [7, 8.0, false],
	"bombear": [8, 10.0, true],
}
const ONE_SHOTS := ["lanterna_ligar", "lanterna_desligar", "pegar", "interagir"]

## Single right hand, bottom right of the 320x240 view. The 160x120 frames keep the hand in their
## right-hand part; HAND_SCALE shrinks the whole set, HAND_CENTER_X / HAND_BOTTOM_CUT place it.
const HAND_SCALE := 1.5
const HAND_CENTER_X := 0.77       ## fraction of the view width where the hand's centre sits
const HAND_ANCHOR_X := 112.0      ## x of the hand's centre inside the 160x120 frame
const HAND_BOTTOM_CUT := 4.0      ## frame pixels pushed below the bottom edge (before scaling)
## clips whose frames have a lit-lens variant (folder name + "_luz") while the flashlight is on
const LIT_CLIPS := ["andar", "correr"]
## [still, walking, running] per thing in hand
const SETS := {
	"flashlight": ["lanterna_idle", "andar", "correr"],
	"can": ["segurar_lata", "andar_lata", "correr_lata"],
	"empty": ["idle", "andar_vazio", "correr_vazio"],
}

@export var player: Player

var _sprite: AnimatedSprite2D
var _one_shot := ""
var _lit := false
var _frames_off: SpriteFrames
var _frames_on: SpriteFrames


func _ready() -> void:
	layer = 3
	add_to_group("hands")
	_sprite = AnimatedSprite2D.new()
	_sprite.centered = false
	_sprite.scale = Vector2(HAND_SCALE, HAND_SCALE)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_frames_off = _build_frames(false)
	_frames_on = _build_frames(true)
	_sprite.sprite_frames = _frames_off
	add_child(_sprite)
	_sprite.animation_finished.connect(_on_finished)
	get_viewport().size_changed.connect(_layout)
	_layout()
	GameState.flashlight_toggled.connect(func(on: bool) -> void:
		if held_kind() == "flashlight":
			_play_once("lanterna_ligar" if on else "lanterna_desligar"))
	GameState.hotbar_changed.connect(_end_flashlight_shot)
	GameState.weapon_changed.connect(_layout)
	GameState.item_given.connect(func(_id: String) -> void: _play_once("pegar"))
	GameState.panel_changed.connect(func(_open: bool) -> void: _refresh())
	Settings.applied.connect(_refresh)
	if player:
		player.interacted.connect(func(_t: Interactable) -> void:
			if _one_shot != "pegar":
				_play_once("interagir"))
		player.hold_progress_changed.connect(func(ratio: float) -> void:
			if ratio > 0.0 and _one_shot == "":
				_play_once("interagir"))
	_refresh()
	_update_state()


func current_animation() -> String:
	return _sprite.animation


## What this hand holds: "flashlight", "can" or "empty".
func held_kind() -> String:
	if GameState.equipped != "":
		return "flashlight" if GameState.has_flashlight else "empty"
	match GameState.held_item():
		"flashlight":
			return "flashlight"
		"oil", "fuel":
			return "can"
	return "empty"


## A flashlight click must not keep playing once something else is in hand.
func _end_flashlight_shot() -> void:
	if _one_shot.begins_with("lanterna_") and held_kind() != "flashlight":
		_one_shot = ""
		_update_state()


func _process(_delta: float) -> void:
	_refresh()
	if visible:
		_update_state()


func _layout() -> void:
	var size := get_viewport().get_visible_rect().size
	# With a weapon in the right hand (3D viewmodel) the flashlight hand mirrors to the left.
	var armed: bool = GameState.equipped != ""
	_sprite.flip_h = armed
	var x := size.x * (1.0 - HAND_CENTER_X) - (160.0 - HAND_ANCHOR_X) * HAND_SCALE if armed else size.x * HAND_CENTER_X - HAND_ANCHOR_X * HAND_SCALE
	_sprite.position = Vector2(x, size.y - (120.0 - HAND_BOTTOM_CUT) * HAND_SCALE)


func _refresh() -> void:
	visible = Settings.values.get("hands", true) and GameState.in_game and not GameState.dead \
		and not GameState.finished and not GameState.panel_open


func _build_frames(lit: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip: String in CLIPS:
		var info: Array = CLIPS[clip]
		frames.add_animation(clip)
		frames.set_animation_speed(clip, info[1])
		frames.set_animation_loop(clip, info[2])
		for i in int(info[0]):
			var folder := clip + "_luz" if lit and clip in LIT_CLIPS else clip
			frames.add_frame(clip, load("%s%s/%02d.png" % [FOLDER, folder, i]))
	return frames


func _play_once(clip: String) -> void:
	_one_shot = clip
	_sprite.play(clip)


func _on_finished() -> void:
	if _one_shot != "":
		_one_shot = ""
		_update_state()


func _update_state() -> void:
	if _one_shot != "":
		return
	var clips: Array = SETS[held_kind()]
	var moving := player != null and Vector2(player.velocity.x, player.velocity.z).length() > 0.5 and player.is_on_floor()
	var want: String = clips[0]
	if moving:
		want = clips[2] if GameState.sprinting else clips[1]
	var lit: bool = GameState.flashlight_on and held_kind() == "flashlight"
	if lit != _lit:
		_lit = lit
		_sprite.sprite_frames = _frames_on if lit else _frames_off
		_sprite.play(want)
	if _sprite.animation != want or not _sprite.is_playing():
		_sprite.play(want)
