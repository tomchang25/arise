class_name MovementModule
extends Node

@export var character: CharacterBody2D
@export var acceleration: float = 10000.0
@export var deceleration: float = 16000.0
@export var knockback_friction: float = 1200.0

var manual_velocity: Vector2 = Vector2.ZERO
var path_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

var use_manual := true
var use_path := false


func _physics_process(delta: float) -> void:
    if character == null:
        return

    var target_move := Vector2.ZERO

    if use_manual:
        target_move += manual_velocity

    if use_path:
        target_move += path_velocity

    var current_move := character.velocity - knockback_velocity
    var rate := acceleration if target_move != Vector2.ZERO else deceleration
    current_move = current_move.move_toward(target_move, rate * delta)

    knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

    character.velocity = current_move + knockback_velocity
    character.move_and_slide()


func set_manual_velocity(v: Vector2) -> void:
    manual_velocity = v


func set_move_direction(direction: Vector2, speed: float) -> void:
    manual_velocity = direction.normalized() * speed


func set_path_velocity(v: Vector2) -> void:
    path_velocity = v


func apply_knockback(impulse: Vector2, velocity_cap: float = -1.0) -> void:
    knockback_velocity += impulse

    if velocity_cap > 0.0 and knockback_velocity.length() > velocity_cap:
        knockback_velocity = knockback_velocity.normalized() * velocity_cap


func set_knockback_velocity(v: Vector2, velocity_cap: float = -1.0) -> void:
    knockback_velocity = v

    if velocity_cap > 0.0 and knockback_velocity.length() > velocity_cap:
        knockback_velocity = knockback_velocity.normalized() * velocity_cap


func clear_knockback() -> void:
    knockback_velocity = Vector2.ZERO


func set_manual_mode() -> void:
    use_manual = true
    use_path = false
    path_velocity = Vector2.ZERO


func set_path_mode() -> void:
    use_manual = false
    use_path = true
    manual_velocity = Vector2.ZERO


func stop_all_motion() -> void:
    manual_velocity = Vector2.ZERO
    path_velocity = Vector2.ZERO


func stop_manual_motion() -> void:
    manual_velocity = Vector2.ZERO
