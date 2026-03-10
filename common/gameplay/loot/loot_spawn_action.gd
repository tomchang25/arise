class_name LootSpawnAction
extends SpawnAction

enum ParentMode { CTX_SPAWN_ROOT, SPAWN_POINT_PARENT, NODEPATH_FROM_SPAWN_POINT, GROUP_NAME }

@export var parent_mode: ParentMode = ParentMode.CTX_SPAWN_ROOT
@export var parent_path: NodePath
@export var parent_group: String = "world"
@export var set_global_position: bool = true

var drop_result: LootDropResult
var spawn_position: Vector2 = Vector2.ZERO


func execute(spawn_point: Node2D, ctx: SpawnContext) -> Node:
    if drop_result == null:
        push_warning("LootSpawnAction: drop_result is null")
        return null

    if drop_result.pickup_scene == null:
        push_warning("LootSpawnAction: pickup_scene is null")
        return null

    var parent := _resolve_parent(spawn_point, ctx)
    if parent == null:
        push_warning("LootSpawnAction: parent is null")
        return null

    var inst := drop_result.pickup_scene.instantiate()
    if inst == null:
        return null

    parent.add_child.call_deferred(inst)

    if set_global_position and inst is Node2D:
        (inst as Node2D).global_position = spawn_position

    if inst.has_method("setup_from_drop_result"):
        inst.call_deferred("setup_from_drop_result", drop_result)

    return inst


func _resolve_parent(spawn_point: Node2D, ctx: SpawnContext) -> Node:
    match parent_mode:
        ParentMode.CTX_SPAWN_ROOT:
            if ctx != null and ctx.spawn_root != null:
                return ctx.spawn_root
            return spawn_point.get_parent() if spawn_point != null else null

        ParentMode.SPAWN_POINT_PARENT:
            return spawn_point.get_parent() if spawn_point != null else null

        ParentMode.NODEPATH_FROM_SPAWN_POINT:
            if spawn_point == null:
                return null
            if parent_path == NodePath():
                push_warning("LootSpawnAction: parent_path is empty")
                return null
            return spawn_point.get_node_or_null(parent_path)

        ParentMode.GROUP_NAME:
            var tree := spawn_point.get_tree() if spawn_point != null else null
            if tree == null:
                return null
            return tree.get_first_node_in_group(parent_group)

    return null
