class_name Player
extends CharacterBody3D
## First-person keeper: walking, mouse look and the interaction ray.

signal focus_changed(target: Interactable)
signal hold_progress_changed(ratio: float)
signal stepped
signal jumped
signal landed
signal interacted(target: Interactable)

@export var walk_speed := 3.5
@export var sprint_speed := 5.5
@export var acceleration := 14.0
@export var jump_velocity := 4.2
@export var mouse_sensitivity := 0.0025
@export var stick_sensitivity := 3.2 ## radians per second at full deflection
@export var stride := 2.0 ## meters between footstep sounds
## Falling below this height (into the sea) respawns at the start position.
@export var respawn_height := -10.0
## Feet below this height are in the sea (the water plane sits at -1.2).
@export var water_height := -1.0
## Drops longer than this hurt: (height - safe_fall) * fall_damage.
@export var safe_fall := 3.0
@export var fall_damage := 12.0

## True while a console holds the keeper's hands: no walking, looking or world interaction.
## The world keeps running.
var locked := false:
	set(value):
		locked = value
		_wait_release = true
		_set_hold(0.0)
		if value and _focus:
			_focus = null
			focus_changed.emit(null)
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _spawn: Transform3D
var _focus: Interactable
var _hold_elapsed := 0.0
var _wait_release := false
var _step_distance := 0.0
var _was_on_floor := true
var _air_peak := 0.0

@onready var _head: Node3D = $Head
@onready var _ray: RayCast3D = $Head/Camera3D/InteractRay


func _ready() -> void:
	add_to_group("player")
	GameState.player = self
	_spawn = global_transform
	_air_peak = global_position.y
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative ignores the 320x240 stretch, keeping sensitivity stable.
		var motion: Vector2 = event.screen_relative
		rotate_y(-motion.x * mouse_sensitivity)
		_head.rotate_x(-motion.y * mouse_sensitivity)
		_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func apply_settings(mouse: float, stick: float, fov: float) -> void:
	mouse_sensitivity = mouse
	stick_sensitivity = stick
	$Head/Camera3D.fov = fov


func _physics_process(delta: float) -> void:
	var look := Vector2.ZERO if locked else Input.get_vector("look_left", "look_right", "look_up", "look_down")
	rotate_y(-look.x * stick_sensitivity * delta)
	_head.rotate_x(-look.y * stick_sensitivity * delta)
	_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump") and not locked:
		velocity.y = jump_velocity
		jumped.emit()

	var frozen := locked or GameState.dead
	var input := Vector2.ZERO if frozen else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var sprinting := Input.is_action_pressed("sprint") and input != Vector2.ZERO and GameState.can_sprint()
	GameState.sprinting = sprinting
	var speed := sprint_speed if sprinting else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	move_and_slide()
	_emit_footsteps(delta)

	GameState.in_water = global_position.y < water_height
	if global_position.y < respawn_height:
		global_transform = _spawn
		velocity = Vector3.ZERO
		_air_peak = global_position.y

	if not locked:
		_update_interaction(delta)


func _emit_footsteps(delta: float) -> void:
	var on_floor := is_on_floor()
	if not on_floor:
		_air_peak = maxf(_air_peak, global_position.y)
	if on_floor and not _was_on_floor:
		landed.emit()
		var drop := _air_peak - global_position.y
		if drop > safe_fall:
			GameState.damage((drop - safe_fall) * fall_damage, "A queda")
			GameState.play("hurt")
	if on_floor:
		_air_peak = global_position.y
	_was_on_floor = on_floor
	if on_floor and Vector2(velocity.x, velocity.z).length() > 0.5:
		_step_distance += Vector2(velocity.x, velocity.z).length() * delta
		if _step_distance >= stride:
			_step_distance = 0.0
			stepped.emit()


func _update_interaction(delta: float) -> void:
	var target := _ray.get_collider() as Interactable
	if target and not target.enabled:
		target = null
	if target != _focus:
		_focus = target
		_set_hold(0.0)
		focus_changed.emit(target)

	if not Input.is_action_pressed("interact"):
		_wait_release = false
		_set_hold(0.0)
		return
	if _focus == null or _wait_release:
		return

	if _focus.hold_time <= 0.0:
		_complete_interaction()
		return
	_set_hold(_hold_elapsed + delta)
	if _hold_elapsed >= _focus.hold_time:
		_complete_interaction()


func _complete_interaction() -> void:
	_wait_release = true
	_set_hold(0.0)
	interacted.emit(_focus)
	_focus.interact(self)


func _set_hold(value: float) -> void:
	if is_equal_approx(value, _hold_elapsed):
		return
	_hold_elapsed = value
	var ratio := 0.0
	if _focus and _focus.hold_time > 0.0:
		ratio = clampf(_hold_elapsed / _focus.hold_time, 0.0, 1.0)
	hold_progress_changed.emit(ratio)
