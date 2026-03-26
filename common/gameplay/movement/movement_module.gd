@tool
class_name MovementModule
extends Node

@export var enabled := true:
    set = set_enabled

var _enabled: bool = true

@export var character: CharacterBody2D
@export var use_direct_position := false

@export_group("Movement")
@export var acceleration: float = 10000.0
@export var deceleration: float = 16000.0
@export var knockback_friction: float = 1200.0

@export_group("Separation")
@export var max_separation_speed: float = 120.0

var manual_velocity: Vector2 = Vector2.ZERO
var path_velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var separation_velocity: Vector2 = Vector2.ZERO

var use_manual := true
var use_path := false

var crowd_block_ratio: float = 0.0

var _computed_velocity: Vector2 = Vector2.ZERO
var _separation_target: Vector2 = Vector2.ZERO

# -------------------------
# Lifecycle
# -------------------------


func _physics_process(delta: float) -> void:
    if not _enabled:
        return

    if character == null:
        return

    var blocked_manual := manual_velocity * (1.0 - crowd_block_ratio)
    var blocked_path := path_velocity * (1.0 - crowd_block_ratio)
    var target_move := Vector2.ZERO

    if use_manual:
        target_move += blocked_manual

    if use_path:
        target_move += blocked_path

    var current_move := _computed_velocity - knockback_velocity
    var rate := acceleration if target_move != Vector2.ZERO else deceleration
    current_move = current_move.move_toward(target_move, rate * delta)

    knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

    var sep_target := _separation_target.limit_length(max_separation_speed)
    separation_velocity = separation_velocity.lerp(sep_target, 1.0 - exp(-15.0 * delta))

    _computed_velocity = current_move + knockback_velocity + separation_velocity

    if use_direct_position:
        character.global_position += _computed_velocity * delta
    else:
        character.velocity = _computed_velocity
        character.move_and_slide()

# -------------------------
# Common API
# -------------------------


func reset() -> void:
    _enabled = true
    manual_velocity = Vector2.ZERO
    path_velocity = Vector2.ZERO
    knockback_velocity = Vector2.ZERO
    separation_velocity = Vector2.ZERO
    _computed_velocity = Vector2.ZERO
    use_manual = true
    use_path = false
    crowd_block_ratio = 0.0
    _separation_target = Vector2.ZERO


func set_enabled(value: bool) -> void:
    _enabled = value
    if not _enabled:
        _stop_runtime_state()


func is_enabled() -> bool:
    return _enabled


func has_character() -> bool:
    return character != null


func is_using_manual_mode() -> bool:
    return use_manual


func is_using_path_mode() -> bool:
    return use_path


func stop_all_motion(force_clear_knockback: bool = false) -> void:
    manual_velocity = Vector2.ZERO
    path_velocity = Vector2.ZERO

    if force_clear_knockback:
        knockback_velocity = Vector2.ZERO

# -------------------------
# Manual Control
# -------------------------


func set_manual_velocity(velocity: Vector2) -> void:
    if not _enabled:
        return

    manual_velocity = velocity


func set_move_direction(direction: Vector2, speed: float) -> void:
    if not _enabled:
        return

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


func set_path_velocity(velocity: Vector2) -> void:
    if not _enabled:
        return

    path_velocity = velocity


func stop_path_motion() -> void:
    path_velocity = Vector2.ZERO


func set_path_mode() -> void:
    use_manual = false
    use_path = true
    manual_velocity = Vector2.ZERO

# -------------------------
# Knockback
# -------------------------


func apply_knockback(impulse: Vector2, velocity_cap: float = -1.0) -> void:
    if not _enabled:
        return

    knockback_velocity += impulse

    if velocity_cap > 0.0 and knockback_velocity.length() > velocity_cap:
        knockback_velocity = knockback_velocity.normalized() * velocity_cap


func set_knockback_velocity(velocity: Vector2, velocity_cap: float = -1.0) -> void:
    if not _enabled:
        return

    knockback_velocity = velocity

    if velocity_cap > 0.0 and knockback_velocity.length() > velocity_cap:
        knockback_velocity = knockback_velocity.normalized() * velocity_cap


func clear_knockback() -> void:
    knockback_velocity = Vector2.ZERO

# -------------------------
# Separation
# -------------------------


func set_separation(velocity: Vector2) -> void:
    _separation_target = velocity


func set_crowd_block_ratio(value: float) -> void:
    crowd_block_ratio = clamp(value, 0.0, 1.0)
# -------------------------
# Internal Helpers
# -------------------------


func _stop_runtime_state() -> void:
    stop_all_motion()
