class_name SpawnExecutor
extends RefCounted


static func execute_at_node(action: SpawnAction, anchor: Node2D, ctx: SpawnContext) -> Node:
    if action == null:
        Debug.warn("SpawnExecutor: action is null")
        return null

    if not is_instance_valid(anchor):
        Debug.warn("SpawnExecutor: anchor is null or freed")
        return null

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnExecutor: ctx.spawn_parent is null or freed")
        return null

    return action.execute(anchor, ctx)


static func execute_at_position(action: SpawnAction, global_position: Vector2, ctx: SpawnContext) -> Node:
    if action == null:
        Debug.warn("SpawnExecutor: action is null")
        return null

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnExecutor: ctx.spawn_parent is null or freed")
        return null

    var temp_anchor := Node2D.new()
    ctx.spawn_parent.add_child(temp_anchor)
    temp_anchor.global_position = global_position

    var result := action.execute(temp_anchor, ctx)

    temp_anchor.queue_free()
    return result
