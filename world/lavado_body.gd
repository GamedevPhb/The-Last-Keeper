extends Node3D
## The body of one Lavado (set as the script of the character root by `lavados.gd`): hit points,
## knockback, the stagger after a hit and a short death. Group "enemies": the weapons find it
## there and call `take_damage()`. `lavados.gd` reads `stun`, `alert` and `consume_knock()`.

signal died(body: Node3D)

const MAX_HEALTH := 60.0
const LIE_TIME := 3.0 ## seconds on the ground before it sinks away

var health := MAX_HEALTH
var dead := false
## Set by `lavados.gd`: invasion foe (hunts the keeper) and its speed multiplier.
var invader := false
var speed_scale := 1.0
var hit_height := 1.8
var hit_radius := 0.45
## While > 0 the Lavado does not walk (it reels).
var stun := 0.0
## While > 0 it heads for `alert_at` (a noise) instead of the tower.
var alert := 0.0
var alert_at := Vector3.ZERO

var _knock := Vector3.ZERO
var _pending_push := 0.0


func _ready() -> void:
	add_to_group("enemies")


## Sets how long the next hit staggers it and how hard it is pushed (set by the weapon first).
func stagger(seconds: float, push: float) -> void:
	stun = maxf(stun, seconds)
	_pending_push = push


func take_damage(amount: float, dir := Vector3.ZERO) -> void:
	if dead:
		return
	health -= amount
	if dir.length() > 0.01:
		_knock += dir.normalized() * _pending_push * 2.0
	_pending_push = 0.0
	GameState.play("lavado_hurt", global_position + Vector3.UP)
	if health <= 0.0:
		_die()


## The displacement of this frame's knockback (decays quickly).
func consume_knock(delta: float) -> Vector3:
	stun = maxf(stun - delta, 0.0)
	alert = maxf(alert - delta, 0.0)
	var step := _knock * delta
	_knock = _knock.move_toward(Vector3.ZERO, 6.0 * delta)
	return step


func _die() -> void:
	dead = true
	remove_from_group("enemies")
	var pose := Actors.pose_of(self)
	if pose:
		pose.mode = pose.Mode.IDLE
	died.emit(self)
	GameState.say("O afogado tombou.")
	var fall := create_tween()
	fall.tween_property(self, "rotation:x", -PI / 2.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall.tween_interval(LIE_TIME)
	fall.tween_property(self, "position:y", position.y - 0.7, 1.5)
	fall.tween_callback(queue_free)
