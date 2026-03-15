class_name SpawnWarningExecutor
extends RefCounted


static func execute_at_position(warning_point_scene: PackedScene, action: SpawnAction, global_position: Vector2, ctx: SpawnContext) -> Node:
    if warning_point_scene == null:
        Debug.warn("SpawnWarningExecutor: warning_point_scene is null")
        return null

    if action == null:
        Debug.warn("SpawnWarningExecutor: action is null")
        return null

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnWarningExecutor: ctx.spawn_parent is null or freed")
        return null

    var point := warning_point_scene.instantiate() as WarningSpawnPoint
    if point == null:
        Debug.warn("SpawnWarningExecutor: scene root is not WarningSpawnPoint")
        return null

    ctx.spawn_parent.add_child(point)
    point.global_position = global_position
    point.setup(action, ctx)

    return await point.start()
