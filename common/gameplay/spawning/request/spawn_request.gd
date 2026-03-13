class_name SpawnRequest
extends RefCounted

const DEFAULT_WARNING_SPAWN_POINT_SCENE := preload("res://common/gameplay/spawning/points/warning_spawn_point.tscn")

var action: SpawnAction
var global_position: Vector2 = Vector2.ZERO
var spawn_parent: Node

var use_warning_spawn := false

var source_node: Node
var rng_seed: int = 0
var metadata: Dictionary = {}

var ctx: SpawnContext


func setup_direct(
    request_action: SpawnAction,
    request_global_position: Vector2,
    request_spawn_parent: Node,
    request_source_node: Node = null,
    request_rng_seed: int = 0,
    request_metadata: Dictionary = {},
    request_ctx: SpawnContext = null
) -> SpawnRequest:
    action = request_action
    global_position = request_global_position
    spawn_parent = request_spawn_parent
    use_warning_spawn = false
    source_node = request_source_node
    rng_seed = request_rng_seed
    metadata = request_metadata.duplicate(true)
    ctx = request_ctx
    return self


func setup_warning(
    request_action: SpawnAction,
    request_global_position: Vector2,
    request_spawn_parent: Node,
    request_source_node: Node = null,
    request_rng_seed: int = 0,
    request_metadata: Dictionary = {},
    request_ctx: SpawnContext = null
) -> SpawnRequest:
    action = request_action
    global_position = request_global_position
    spawn_parent = request_spawn_parent
    use_warning_spawn = true
    source_node = request_source_node
    rng_seed = request_rng_seed
    metadata = request_metadata.duplicate(true)
    ctx = request_ctx
    return self


func execute() -> SpawnResult:
    if action == null:
        Debug.warn("SpawnRequest: action is null")
        return SpawnResult.create_failed("action is null", global_position, metadata)

    if spawn_parent == null:
        Debug.warn("SpawnRequest: spawn_parent is null")
        return SpawnResult.create_failed("spawn_parent is null", global_position, metadata)

    var resolved_ctx := _resolve_context()
    var spawned_node: Node = null

    if use_warning_spawn:
        spawned_node = await SpawnWarningExecutor.execute_at_position(DEFAULT_WARNING_SPAWN_POINT_SCENE, action, global_position, spawn_parent, resolved_ctx)
    else:
        spawned_node = SpawnExecutor.execute_at_position(action, global_position, spawn_parent, resolved_ctx)

    if spawned_node == null:
        return SpawnResult.create_failed("spawn returned null", global_position, metadata)

    return SpawnResult.create_success(spawned_node, global_position, use_warning_spawn, metadata)


func _resolve_context() -> SpawnContext:
    if ctx != null:
        if ctx.spawn_parent == null:
            ctx.spawn_parent = spawn_parent

        if ctx.source_node == null:
            ctx.source_node = source_node

        if ctx.rng_seed == 0 and rng_seed != 0:
            ctx.rng_seed = rng_seed

        if not metadata.is_empty():
            var merged_metadata := ctx.metadata.duplicate(true)
            merged_metadata.merge(metadata, true)
            ctx.metadata = merged_metadata

        return ctx

    var resolved_ctx := SpawnContext.new()
    resolved_ctx.setup(spawn_parent, rng_seed, source_node, metadata.duplicate(true))
    return resolved_ctx
