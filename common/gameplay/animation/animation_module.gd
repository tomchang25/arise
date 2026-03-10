@tool
class_name AnimationModule
extends Node

signal animation_finished(anim_name: StringName)

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_state()

@export var actor: Node2D
@export var animation_tree: AnimationTree

@export_group("AnimationTree Paths")
@export var state_machine_path: String = "parameters/StateMachine/playback"
@export var time_scale_path: String = "parameters/TimeScale/scale"

@export_group("Behavior")
@export var reset_time_scale_on_disable := true

var _playback: AnimationNodeStateMachinePlayback
var _last_direction: Vector2 = Vector2.DOWN

# -------------------------
# Lifecycle
# -------------------------


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _cache_handles()


func _ready() -> void:
    _cache_handles()
    _connect_signals()


# -------------------------
# Common API
# -------------------------


func set_enabled(value: bool, restore_defaults: bool = true) -> void:
    enabled = value

    if not enabled and restore_defaults:
        _stop_runtime_state()


func is_enabled() -> bool:
    return enabled


func has_animation_tree() -> bool:
    return animation_tree != null


func has_playback() -> bool:
    return _playback != null


# -------------------------
# State Travel
# -------------------------


func travel(state_name: StringName) -> void:
    if not enabled:
        return

    if _playback == null:
        return

    _playback.travel(state_name)


# -------------------------
# Blend / Facing
# -------------------------


func set_blend_position(direction: Vector2, state_name: StringName) -> void:
    if not enabled:
        return

    if animation_tree == null:
        return

    var resolved_direction := direction.normalized()
    if resolved_direction == Vector2.ZERO:
        resolved_direction = _last_direction
    else:
        _last_direction = resolved_direction

    var path := _get_blend_position_path(state_name)
    if path.is_empty():
        return

    animation_tree.set(path, resolved_direction)


func face_direction(direction: Vector2) -> void:
    if direction == Vector2.ZERO:
        return

    _last_direction = direction.normalized()


func get_last_direction() -> Vector2:
    return _last_direction


# -------------------------
# Playback Parameters
# -------------------------


func set_time_scale(scale: float) -> void:
    if animation_tree == null:
        return

    animation_tree.set(time_scale_path, scale)


# -------------------------
# Internal Helpers
# -------------------------


func _cache_handles() -> void:
    _playback = null

    if animation_tree == null:
        return

    _playback = animation_tree.get(state_machine_path) as AnimationNodeStateMachinePlayback


func _connect_signals() -> void:
    if animation_tree == null:
        return

    if not animation_tree.animation_finished.is_connected(_on_animation_finished):
        animation_tree.animation_finished.connect(_on_animation_finished)


func _stop_runtime_state() -> void:
    if reset_time_scale_on_disable:
        set_time_scale(1.0)


func _get_blend_position_path(state_name: StringName) -> String:
    if state_machine_path.is_empty():
        return ""

    var base_path := state_machine_path.trim_suffix("/playback")
    return "%s/%s/blend_position" % [base_path, String(state_name)]


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_animation_finished(anim_name: StringName) -> void:
    animation_finished.emit(anim_name)
