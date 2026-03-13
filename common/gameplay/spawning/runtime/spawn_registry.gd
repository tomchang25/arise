class_name SpawnRegistry
extends RefCounted

var _tracked_nodes: Array[WeakRef] = []


func register_node(node: Node) -> bool:
    if node == null:
        return false

    cleanup_invalid()

    if has_node(node):
        return false

    _tracked_nodes.append(weakref(node))
    return true


func unregister_node(node: Node) -> void:
    if node == null:
        return

    var next_nodes: Array[WeakRef] = []

    for weak_node in _tracked_nodes:
        if weak_node == null:
            continue

        var tracked_node = weak_node.get_ref()
        if tracked_node == null:
            continue

        if tracked_node == node:
            continue

        if not is_instance_valid(tracked_node):
            continue

        next_nodes.append(weak_node)

    _tracked_nodes = next_nodes


func has_node(node: Node) -> bool:
    if node == null:
        return false

    for weak_node in _tracked_nodes:
        if weak_node == null:
            continue

        var tracked_node = weak_node.get_ref()
        if tracked_node == null:
            continue

        if not is_instance_valid(tracked_node):
            continue

        if tracked_node == node:
            return true

    return false


func cleanup_invalid() -> void:
    var next_nodes: Array[WeakRef] = []

    for weak_node in _tracked_nodes:
        if weak_node == null:
            continue

        var tracked_node = weak_node.get_ref()
        if tracked_node == null:
            continue

        if not is_instance_valid(tracked_node):
            continue

        next_nodes.append(weak_node)

    _tracked_nodes = next_nodes


func clear() -> void:
    _tracked_nodes.clear()


func get_valid_nodes() -> Array[Node]:
    cleanup_invalid()

    var result: Array[Node] = []

    for weak_node in _tracked_nodes:
        if weak_node == null:
            continue

        var tracked_node = weak_node.get_ref()
        if tracked_node == null:
            continue

        if not is_instance_valid(tracked_node):
            continue

        result.append(tracked_node)

    return result


func get_valid_nodes_2d() -> Array[Node2D]:
    cleanup_invalid()

    var result: Array[Node2D] = []

    for weak_node in _tracked_nodes:
        if weak_node == null:
            continue

        var tracked_node = weak_node.get_ref()
        if tracked_node == null:
            continue

        if not is_instance_valid(tracked_node):
            continue

        var node_2d := tracked_node as Node2D
        if node_2d != null:
            result.append(node_2d)

    return result


func get_valid_count() -> int:
    cleanup_invalid()
    return _tracked_nodes.size()


func queue_free_all() -> void:
    for node in get_valid_nodes():
        if is_instance_valid(node):
            node.queue_free()

    clear()
