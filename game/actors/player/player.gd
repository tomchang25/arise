@tool
class_name Player
extends CharacterBody2D

signal roll_finished
signal attack_finished

@export var stats: Stats

@export_group("Modules")
@export var movement_module: MovementModule
@export var animation_module: AnimationModule
@export var combat_module: CombatModule
@export var detection_module: DetectionModule
@export var damage_receiver: DamageReceiverModule
@export var hit_feedback: HitFeedbackModule
@export var hurtbox: Hurtbox
@export var state_machine: StateMachine

enum StateId { IDLE, MOVE, ROLL, ATTACK }


class AnimationState:
    const Idle: StringName = &"Idle"
    const Move: StringName = &"Move"
    const Roll: StringName = &"Roll"
    const Attack: StringName = &"Attack"


var _attack_requested := false
var _dodge_requested := false


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire_nodes()
        _connect_stats_signals()
        _refresh_detection_range()


func _ready() -> void:
    _auto_wire_nodes()
    _ensure_stats()
    _bind_modules()

    if animation_module and not animation_module.animation_finished.is_connected(_on_animation_finished):
        animation_module.animation_finished.connect(_on_animation_finished)

    _connect_stats_signals()
    _refresh_detection_range()


func _draw():
    draw_arc(combat_module.position, stats.primary_attack_range, 0, TAU, 64, Color(0, 1, 0), 2.0)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("attack"):
        _attack_requested = true
    elif event.is_action_pressed("dodge"):
        _dodge_requested = true


func get_move_input() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_run_pressed() -> bool:
    return Input.is_action_pressed("run")


func consume_attack_request() -> bool:
    var requested := _attack_requested
    _attack_requested = false
    return requested


func consume_dodge_request() -> bool:
    var requested := _dodge_requested
    _dodge_requested = false
    return requested


func get_primary_attack_range() -> float:
    if not stats:
        return 0.0
    return max(stats.primary_attack_range, 0.0)


func has_auto_attack_target() -> bool:
    return is_instance_valid(get_closest_attack_target())


func get_mouse_world_position() -> Vector2:
    return get_global_mouse_position()


func get_closest_attack_target() -> Node2D:
    if not detection_module:
        return null
    return detection_module.get_closest_target(false)


func get_attack_target_position() -> Vector2:
    var attack_range := get_primary_attack_range()
    var origin := get_attack_origin()
    var target := get_closest_attack_target()

    if is_instance_valid(target):
        var target_pos := target.global_position
        if attack_range <= 0.0:
            return origin

        var to_target := target_pos - origin
        if to_target.length() <= attack_range:
            return target_pos

        if to_target == Vector2.ZERO:
            return origin

        return origin + to_target.normalized() * attack_range

    var mouse_pos := get_mouse_world_position()
    var to_mouse := mouse_pos - origin

    if attack_range <= 0.0:
        return origin

    if to_mouse.length() <= attack_range:
        return mouse_pos

    if to_mouse == Vector2.ZERO:
        return origin + Vector2.DOWN * attack_range

    return origin + to_mouse.normalized() * attack_range


func get_aim_direction() -> Vector2:
    var origin := get_attack_origin()
    var target := get_closest_attack_target()

    if is_instance_valid(target):
        var to_target := target.global_position - origin
        if to_target != Vector2.ZERO:
            return to_target.normalized()

    var mouse_pos := get_mouse_world_position()
    var to_mouse := mouse_pos - origin
    if to_mouse != Vector2.ZERO:
        return to_mouse.normalized()

    var move_input := get_move_input()
    if move_input != Vector2.ZERO:
        return move_input.normalized()

    if animation_module:
        return animation_module.get_last_direction()

    return Vector2.DOWN


func get_attack_origin() -> Vector2:
    if combat_module:
        return combat_module.get_attack_origin()
    return global_position


func apply_knockback(impulse: Vector2) -> void:
    if movement_module:
        movement_module.apply_knockback(impulse)


func play_actor_animation(state_name: StringName, direction: Vector2 = Vector2.ZERO, time_scale: float = 1.0) -> void:
    if not animation_module:
        return

    animation_module.face_direction(direction)
    animation_module.travel(state_name)
    animation_module.set_time_scale(time_scale)

    if direction != Vector2.ZERO:
        animation_module.set_blend_position(direction, state_name)


func _on_animation_finished(anim_name: StringName) -> void:
    var anim_text := String(anim_name)

    if String(AnimationState.Roll) in anim_text:
        roll_finished.emit()
    elif String(AnimationState.Attack) in anim_text:
        attack_finished.emit()


func _on_stats_recalculated() -> void:
    _refresh_detection_range()


func _refresh_detection_range() -> void:
    if detection_module and stats:
        detection_module.set_collision_radius(stats.primary_attack_range)


func _auto_wire_nodes() -> void:
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule
    if not animation_module:
        animation_module = find_child("AnimationModule", true, false) as AnimationModule
    if not combat_module:
        combat_module = find_child("CombatModule", true, false) as CombatModule
    if not detection_module:
        detection_module = find_child("DetectionModule", true, false) as DetectionModule
    if not damage_receiver:
        damage_receiver = find_child("DamageReceiverModule", true, false) as DamageReceiverModule
    if not hit_feedback:
        hit_feedback = find_child("HitFeedbackModule", true, false) as HitFeedbackModule
    if not hurtbox:
        hurtbox = find_child("Hurtbox", true, false) as Hurtbox
    if not state_machine:
        state_machine = find_child("StateMachine", true, false) as StateMachine


func _ensure_stats() -> void:
    if stats:
        stats.setup_stats()
        return

    stats = Stats.new()
    stats.faction = Stats.Faction.PLAYER
    stats.setup_stats()


func _bind_modules() -> void:
    if movement_module:
        movement_module.character = self
        movement_module.set_manual_mode()

    if animation_module:
        animation_module.actor = self

    if combat_module:
        combat_module.stats = stats

    if detection_module and stats:
        detection_module.set_collision_radius(stats.primary_attack_range)

    if hurtbox:
        hurtbox.owner_stats = stats

    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox

    if hit_feedback:
        hit_feedback.stats = stats
        hit_feedback.damage_receiver = damage_receiver


func _connect_stats_signals() -> void:
    if stats and not stats.stats_recalculated.is_connected(_on_stats_recalculated):
        stats.stats_recalculated.connect(_on_stats_recalculated)


func _disconnect_stats_signals() -> void:
    if stats and stats.stats_recalculated.is_connected(_on_stats_recalculated):
        stats.stats_recalculated.disconnect(_on_stats_recalculated)
