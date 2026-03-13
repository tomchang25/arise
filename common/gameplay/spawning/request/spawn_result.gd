class_name SpawnResult
extends RefCounted

var success := false
var spawned_node: Node
var requested_global_position: Vector2 = Vector2.ZERO
var final_global_position: Vector2 = Vector2.ZERO
var used_warning_spawn := false
var blocked_reason := ""
var metadata: Dictionary = {}


static func create_failed(reason: String, requested_position: Vector2 = Vector2.ZERO, extra_metadata: Dictionary = {}) -> SpawnResult:
    var result := SpawnResult.new()
    result.success = false
    result.blocked_reason = reason
    result.requested_global_position = requested_position
    result.final_global_position = requested_position
    result.metadata = extra_metadata.duplicate(true)
    return result


static func create_success(node: Node, requested_position: Vector2 = Vector2.ZERO, warning_used: bool = false, extra_metadata: Dictionary = {}) -> SpawnResult:
    var result := SpawnResult.new()
    result.success = node != null
    result.spawned_node = node
    result.requested_global_position = requested_position
    result.final_global_position = _resolve_node_global_position(node, requested_position)
    result.used_warning_spawn = warning_used
    result.metadata = extra_metadata.duplicate(true)

    if node == null:
        result.blocked_reason = "spawn returned null"

    return result


func has_node() -> bool:
    return spawned_node != null and is_instance_valid(spawned_node)


func get_node_2d() -> Node2D:
    if not has_node():
        return null
    return spawned_node as Node2D


static func _resolve_node_global_position(node: Node, fallback: Vector2) -> Vector2:
    var node_2d := node as Node2D
    if node_2d != null:
        return node_2d.global_position

    return fallback
