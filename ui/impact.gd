extends CanvasLayer
## Impact feedback (flash + shake), modern in timing but PS1 in look: the white flash fades in 3
## hard alpha steps (no smooth ramp) and the camera shakes in discrete 20 fps jumps. Listens to
## `GameState.impact` (story scenes, enemies emerging). Layer 4: under the PsxPost filter, so
## dithering and CRT still apply. Honors the "Efeitos de impacto" option.

const FLASH_TIME := 0.12
const FLASH_STEPS := 3
const FLASH_ALPHA := 0.7
const SHAKE_TIME := 0.3
const SHAKE_STEP := 0.05

var _rect: ColorRect
var _flash_left := 0.0
var _shake := 0.0
var _shake_left := 0.0
var _shake_tick := 0.0


## Alpha of the flash `left` seconds from its end, in FLASH_STEPS hard steps (also used by story scenes).
static func step_alpha(ratio: float) -> float:
	return ceilf(clampf(ratio, 0.0, 1.0) * FLASH_STEPS) / FLASH_STEPS * FLASH_ALPHA


func _ready() -> void:
	layer = 4
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(1, 1, 1, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	GameState.impact.connect(_on_impact)


func _on_impact(flash: bool, shake: float) -> void:
	if not Settings.values.get("impact", true):
		return
	if flash:
		_flash_left = FLASH_TIME
	if shake > 0.0:
		_shake = shake
		_shake_left = SHAKE_TIME


func is_active() -> bool:
	return _flash_left > 0.0 or _shake_left > 0.0


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	_rect.color.a = step_alpha(_flash_left / FLASH_TIME)
	var camera: Camera3D = null
	var player := get_tree().get_first_node_in_group("player")
	if player:
		camera = player.get_node_or_null("Head/Camera3D")
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		_shake_tick -= delta
		if _shake_tick <= 0.0 and camera:
			_shake_tick = SHAKE_STEP
			var amp := _shake * _shake_left / SHAKE_TIME
			camera.h_offset = randf_range(-amp, amp)
			camera.v_offset = randf_range(-amp, amp)
		if _shake_left <= 0.0 and camera:
			camera.h_offset = 0.0
			camera.v_offset = 0.0
