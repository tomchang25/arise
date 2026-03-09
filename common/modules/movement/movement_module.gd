@tool
class_name MovementModule
extends Node

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_motion()

@export var character: CharacterBody2D

@export_group("Movement")
@export var acceleration: float = 10000.0
@export var deceleration: float = 16000.0
@export var knockback_friction: float = 1200.0

var manual_velocity: Vector2 = Vector2.ZERO
var path_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

var use_manual := true
var use_path := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _auto_wire()


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire()


func _physics_process(delta: float) -> void:
    if not enabled:
        return

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


# -------------------------
# Common API
# -------------------------


func _auto_wire() -> void:
    if character == null:
        character = get_parent() as CharacterBody2D


func _stop_runtime_motion() -> void:
    stop_all_motion()


func set_enabled(value: bool, clear_motion: bool = true) -> void:
    enabled = value

    if not enabled and clear_motion:
        _stop_runtime_motion()


func stop_all_motion(force_clear_knockback: bool = true) -> void:
    manual_velocity = Vector2.ZERO
    path_velocity = Vector2.ZERO

    if force_clear_knockback:
        knockback_velocity = Vector2.ZERO

    if character:
        character.velocity = Vector2.ZERO


func is_enabled() -> bool:
    return enabled


func is_using_manual_mode() -> bool:
    return use_manual


func is_using_path_mode() -> bool:
    return use_path


# -------------------------
# Manual Control
# -------------------------


func set_manual_velocity(v: Vector2) -> void:
    manual_velocity = v


func set_move_direction(direction: Vector2, speed: float) -> void:
    if direction == Vector2.ZERO:
        manual_velocity = Vector2.ZERO
        return

    manual_velocity = direction.normalized() * speed


func stop_manual_motion() -> void:
    manual_velocity = Vector2.ZERO


func set_manual_mode() -> void:
    use_manual = true
    use_path = false
    path_velocity = Vector2.ZERO


# -------------------------
# Path Control
# -------------------------


func set_path_velocity(v: Vector2) -> void:
    path_velocity = v


func stop_path_motion() -> void:
    path_velocity = Vector2.ZERO


func set_path_mode() -> void:
    use_manual = false
    use_path = true
    manual_velocity = Vector2.ZERO


# -------------------------
# Knockback Control
# -------------------------


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
