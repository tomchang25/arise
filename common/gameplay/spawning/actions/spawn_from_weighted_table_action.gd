class_name SpawnFromWeightedTableAction
extends SpawnAction

@export var table: WeightedSceneTable
@export var parent_mode: SpawnPackedSceneAction.ParentMode = SpawnPackedSceneAction.ParentMode.CTX_SPAWN_ROOT
@export var parent_path: NodePath
@export var parent_group: String = "world"
@export var set_global_position: bool = true


func execute(spawn_point: Node2D, ctx: SpawnContext) -> Node:
    if table == null:
        push_warning("SpawnFromWeightedTableAction: table is null")
        return null

    var rng := ctx.ensure_rng() if ctx != null else null
    var picked_scene := table.pick_scene(rng)
    if picked_scene == null:
        # table already push_error/warning
        return null

    var action := SpawnPackedSceneAction.new()
    action.scene = picked_scene
    action.parent_mode = parent_mode
    action.parent_path = parent_path
    action.parent_group = parent_group
    action.set_global_position = set_global_position
    return action.execute(spawn_point, ctx)
