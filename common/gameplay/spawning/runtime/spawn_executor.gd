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

    return action.execute(anchor.global_transform, ctx)


static func execute_at_position(action: SpawnAction, global_position: Vector2, ctx: SpawnContext) -> Node:
    if action == null:
        Debug.warn("SpawnExecutor: action is null")
        return null

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnExecutor: ctx.spawn_parent is null or freed")
        return null

    return action.execute(Transform2D(0.0, global_position), ctx)
