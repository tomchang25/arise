class_name SpawnRequest
extends RefCounted

const DEFAULT_WARNING_SPAWN_POINT_SCENE := preload("res://common/gameplay/spawning/points/warning_spawn_point.tscn")

var action: SpawnAction
var global_position: Vector2 = Vector2.ZERO
var use_warning_spawn := false
var ctx: SpawnContext


func setup_direct(
        request_action: SpawnAction,
        request_global_position: Vector2,
        request_ctx: SpawnContext,
) -> SpawnRequest:
    action = request_action
    global_position = request_global_position
    use_warning_spawn = false
    ctx = request_ctx
    return self


func setup_warning(
        request_action: SpawnAction,
        request_global_position: Vector2,
        request_ctx: SpawnContext,
) -> SpawnRequest:
    action = request_action
    global_position = request_global_position
    use_warning_spawn = true
    ctx = request_ctx
    return self


func execute() -> SpawnResult:
    if action == null:
        Debug.warn("SpawnRequest: action is null")
        return SpawnResult.create_failed("action is null", global_position)

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnRequest: ctx.spawn_parent is null or freed")
        return SpawnResult.create_failed("spawn_parent is null or freed", global_position)

    var spawned_node: Node = null

    if use_warning_spawn:
        spawned_node = await SpawnWarningExecutor.execute_at_position(
            DEFAULT_WARNING_SPAWN_POINT_SCENE,
            action,
            global_position,
            ctx,
        )
    else:
        spawned_node = SpawnExecutor.execute_at_position(action, global_position, ctx)

    if spawned_node == null:
        return SpawnResult.create_failed("spawn returned null", global_position, ctx.metadata)

    return SpawnResult.create_success(spawned_node, global_position, use_warning_spawn, ctx.metadata)
