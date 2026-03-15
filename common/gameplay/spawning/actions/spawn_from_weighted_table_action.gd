class_name SpawnFromWeightedTableAction
extends SpawnAction

@export var table: WeightedSceneTable

@export_group("Transform")
@export var use_anchor_position: bool = true
@export var use_anchor_rotation: bool = false
@export var random_rotation: bool = false

@export_group("Offset")
@export var local_offset: Vector2 = Vector2.ZERO
@export var scatter_radius: float = 0.0


func execute(anchor: Node2D, ctx: SpawnContext) -> Node:
    if table == null:
        Debug.warn("SpawnFromWeightedTableAction: table is null")
        return null

    if ctx == null:
        Debug.warn("SpawnFromWeightedTableAction: ctx is null")
        return null

    var picked_scene := table.pick_scene(ctx.get_rng())
    if picked_scene == null:
        return null

    var packed_scene_action := SpawnPackedSceneAction.new()
    packed_scene_action.scene = picked_scene
    packed_scene_action.use_anchor_position = use_anchor_position
    packed_scene_action.use_anchor_rotation = use_anchor_rotation
    packed_scene_action.random_rotation = random_rotation
    packed_scene_action.local_offset = local_offset
    packed_scene_action.scatter_radius = scatter_radius

    return packed_scene_action.execute(anchor, ctx)
