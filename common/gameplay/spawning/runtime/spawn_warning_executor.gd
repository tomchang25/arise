class_name SpawnWarningExecutor
extends RefCounted


static func execute_at_position(
    warning_point_scene: PackedScene, action: SpawnAction, global_position: Vector2, spawn_parent: Node, ctx: SpawnContext = null
) -> Node:
    if warning_point_scene == null:
        Debug.warn("SpawnWarningExecutor: warning_point_scene is null")
        return null

    if action == null:
        Debug.warn("SpawnWarningExecutor: action is null")
        return null

    if spawn_parent == null:
        Debug.warn("SpawnWarningExecutor: spawn_parent is null")
        return null

    var point := warning_point_scene.instantiate() as WarningSpawnPoint
    if point == null:
        Debug.warn("SpawnWarningExecutor: scene root is not WarningSpawnPoint")
        return null

    spawn_parent.add_child(point)
    point.global_position = global_position
    point.spawn_parent = spawn_parent
    point.setup(action, ctx)

    return await point.start()
