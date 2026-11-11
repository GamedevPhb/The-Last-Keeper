class_name Player
extends CharacterBody3D
## First-person keeper: walking, mouse look and the interaction ray.

signal focus_changed(target: Interactable)
signal hold_progress_changed(ratio: float)

@export var walk_speed := 3.5
@export var sprint_speed := 5.5
@export var acceleration := 14.0
@export var mouse_sensitivity := 0.0025
## Falling below this height (into the sea) respawns at the start position.
@export var respawn_height := -10.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _spawn: Transform3D
var _focus: Interactable
var _hold_elapsed := 0.0
var _wait_release := false

@onready var _head: Node3D = $Head
@onready var _ray: RayCast3D = $Head/Camera3D/InteractRay


func _ready() -> void:
	add_to_group("player")
	_spawn = global_transform
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# screen_relative ignores the 320x240 stretch, keeping sensitivity stable.
		var motion: Vector2 = event.screen_relative
		rotate_y(-motion.x * mouse_sensitivity)
		_head.rotate_x(-motion.y * mouse_sensitivity)
		_head.rotation.x = clampf(_head.rotation.x, deg_to_rad(-85.0), deg_to_rad(85.0))
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
	move_and_slide()

	if global_position.y < respawn_height:
		global_transform = _spawn
		velocity = Vector3.ZERO

	_update_interaction(delta)


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
	_focus.interact(self)


func _set_hold(value: float) -> void:
	if is_equal_approx(value, _hold_elapsed):
		return
	_hold_elapsed = value
	var ratio := 0.0
	if _focus and _focus.hold_time > 0.0:
		ratio = clampf(_hold_elapsed / _focus.hold_time, 0.0, 1.0)
	hold_progress_changed.emit(ratio)
