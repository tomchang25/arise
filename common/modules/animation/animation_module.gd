class_name AnimationModule
extends Node

signal animation_finished(anim_name: StringName)

@export var actor: Node2D
@export var animation_tree: AnimationTree
@export var state_machine_path: String = "parameters/StateMachine/playback"
@export var time_scale_path: String = "parameters/TimeScale/scale"

var _playback: AnimationNodeStateMachinePlayback
var _last_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
    if animation_tree:
        _playback = animation_tree.get(state_machine_path) as AnimationNodeStateMachinePlayback

        if not animation_tree.animation_finished.is_connected(_on_animation_finished):
            animation_tree.animation_finished.connect(_on_animation_finished)


func travel(state_name: StringName) -> void:
    if not _playback:
        return
    _playback.travel(state_name)


func set_time_scale(scale: float) -> void:
    if animation_tree:
        animation_tree.set(time_scale_path, scale)


func set_blend_position(direction: Vector2, state_name: StringName) -> void:
    if not animation_tree:
        return

    var dir := direction.normalized()
    if dir == Vector2.ZERO:
        dir = _last_direction
    else:
        _last_direction = dir

    var path := _get_blend_position_path(state_name)
    if path.is_empty():
        return

    animation_tree.set(path, dir)


func face_direction(direction: Vector2) -> void:
    if direction != Vector2.ZERO:
        _last_direction = direction.normalized()


func get_last_direction() -> Vector2:
    return _last_direction


func _get_blend_position_path(state_name: StringName) -> String:
    if state_machine_path.is_empty():
        return ""

    var base_path := state_machine_path.trim_suffix("/playback")
    return "%s/%s/blend_position" % [base_path, String(state_name)]


func _on_animation_finished(anim_name: StringName) -> void:
    animation_finished.emit(anim_name)
