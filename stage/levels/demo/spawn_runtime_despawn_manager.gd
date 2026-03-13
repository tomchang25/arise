extends Node

@export var enabled: bool = true

@export_group("Tracking")
@export var tracked_target: Node2D

@export_group("Distance Despawn")
@export var use_distance_limit: bool = true
@export var despawn_distance: float = 2200.0

@export_group("Bounds Despawn")
@export var use_play_area_rect: bool = false
@export var play_area_rect: Rect2

@export_group("Runtime")
@export var cleanup_interval: float = 0.25

var _tracked_nodes: Array[Node2D] = []
var _timer: float = 0.0


func _process(delta: float) -> void:
    if not enabled:
        return

    _timer += delta
    if _timer < cleanup_interval:
        return

    _timer = 0.0
    _cleanup_invalid_entries()
    _despawn_outside_rules()


func register_spawned(node: Node) -> void:
    var node_2d := node as Node2D
    if node_2d == null:
        return

    if _tracked_nodes.has(node_2d):
        return

    _tracked_nodes.append(node_2d)


func unregister_spawned(node: Node) -> void:
    var node_2d := node as Node2D
    if node_2d == null:
        return

    _tracked_nodes.erase(node_2d)


func clear_all() -> void:
    _tracked_nodes.clear()


func _cleanup_invalid_entries() -> void:
    var next_nodes: Array[Node2D] = []

    for node in _tracked_nodes:
        if is_instance_valid(node):
            next_nodes.append(node)

    _tracked_nodes = next_nodes


func _despawn_outside_rules() -> void:
    for node in _tracked_nodes:
        if not is_instance_valid(node):
            continue

        if _should_despawn(node):
            node.queue_free()


func _should_despawn(node: Node2D) -> bool:
    if use_distance_limit and tracked_target != null:
        if node.global_position.distance_to(tracked_target.global_position) > despawn_distance:
            return true

    if use_play_area_rect and not play_area_rect.has_point(node.global_position):
        return true

    return false
