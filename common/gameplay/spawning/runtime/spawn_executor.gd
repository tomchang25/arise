class_name SpawnExecutor
extends RefCounted


static func execute_at_node(action: SpawnAction, anchor: Node2D, ctx: SpawnContext = null) -> Node:
    if action == null:
        Debug.warn("SpawnExecutor: action is null")
        return null

    if anchor == null:
        Debug.warn("SpawnExecutor: anchor is null")
        return null

    return action.execute(anchor, ctx)


static func execute_at_position(action: SpawnAction, global_position: Vector2, spawn_parent: Node, ctx: SpawnContext = null) -> Node:
    if action == null:
        Debug.warn("SpawnExecutor: action is null")
        return null

    if spawn_parent == null:
        Debug.warn("SpawnExecutor: spawn_parent is null")
        return null

    var temp_anchor := Node2D.new()
    spawn_parent.add_child(temp_anchor)
    temp_anchor.global_position = global_position

    var result := action.execute(temp_anchor, ctx)

    temp_anchor.queue_free()
    return result
