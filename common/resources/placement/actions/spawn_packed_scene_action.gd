class_name SpawnPackedSceneAction
extends SpawnAction

enum ParentMode { CTX_SPAWN_ROOT, SPAWN_POINT_PARENT, NODEPATH_FROM_SPAWN_POINT, GROUP_NAME }

@export var scene: PackedScene
@export var parent_mode: ParentMode = ParentMode.CTX_SPAWN_ROOT

# Used when parent_mode == NODEPATH_FROM_SPAWN_POINT
@export var parent_path: NodePath

# Used when parent_mode == GROUP_NAME
@export var parent_group: String = "world"

@export var set_global_position: bool = true


func execute(spawn_point: Node2D, ctx: SpawnContext) -> Node:
    if scene == null:
        push_warning("SpawnPackedSceneAction: scene is null")
        return null

    var parent := _resolve_parent(spawn_point, ctx)
    if parent == null:
        push_warning("SpawnPackedSceneAction: parent is null (cannot place)")
        return null

    var inst := scene.instantiate()
    parent.add_child.call_deferred(inst)

    if set_global_position and inst is Node2D:
        (inst as Node2D).global_position = spawn_point.global_position

    return inst


func _resolve_parent(spawn_point: Node2D, ctx: SpawnContext) -> Node:
    match parent_mode:
        ParentMode.CTX_SPAWN_ROOT:
            if ctx != null and ctx.spawn_root != null:
                return ctx.spawn_root
            return spawn_point.get_parent()

        ParentMode.SPAWN_POINT_PARENT:
            return spawn_point.get_parent()

        ParentMode.NODEPATH_FROM_SPAWN_POINT:
            if parent_path == NodePath():
                push_warning("SpawnPackedSceneAction: parent_path is empty")
                return null
            return spawn_point.get_node_or_null(parent_path)

        ParentMode.GROUP_NAME:
            var tree := spawn_point.get_tree()
            if tree == null:
                return null
            return tree.get_first_node_in_group(parent_group)

    return null
