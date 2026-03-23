class_name SpawnPackedSceneAction
extends SpawnAction

@export var scene: PackedScene

@export_group("Pooling")
@export var use_pool: bool = false

@export_group("Transform")
@export var use_anchor_position: bool = true
@export var use_anchor_rotation: bool = false
@export var random_rotation: bool = false

@export_group("Offset")
@export var local_offset: Vector2 = Vector2.ZERO
@export var scatter_radius: float = 0.0


func execute(transform: Transform2D, ctx: SpawnContext) -> Node:
    if scene == null:
        Debug.warn("SpawnPackedSceneAction: scene is null")
        return null

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnPackedSceneAction: ctx.spawn_parent is null or freed")
        return null

    var instance := NodePool.acquire(scene, ctx.spawn_parent, use_pool)

    if instance == null:
        Debug.warn("SpawnPackedSceneAction: failed to instantiate scene")
        return null

    if instance is Node2D:
        var node_2d := instance as Node2D
        var rng := ctx.get_rng()

        var target_position := transform.origin

        if local_offset != Vector2.ZERO:
            target_position += local_offset.rotated(transform.get_rotation())

        if scatter_radius > 0.0:
            if ctx.validator != null:
                var found := SpawnPositionFinder.find_position_in_radius(target_position, scatter_radius, ctx.validator, rng)
                target_position = found if found != null else target_position
            else:
                target_position += SpatialRandomUtils.random_point_in_circle(Vector2.ZERO, scatter_radius, rng)

        if use_anchor_position:
            node_2d.global_position = target_position

        if random_rotation:
            node_2d.global_rotation = rng.randf_range(0.0, TAU)
        elif use_anchor_rotation:
            node_2d.global_rotation = transform.get_rotation()

    return instance


static func create(
        p_scene: PackedScene,
        p_use_pool: bool = true,
        p_use_anchor_position: bool = true,
        p_use_anchor_rotation: bool = false,
        p_random_rotation: bool = false,
        p_local_offset: Vector2 = Vector2.ZERO,
        p_scatter_radius: float = 0.0,
) -> SpawnPackedSceneAction:
    var action := SpawnPackedSceneAction.new()
    action.scene = p_scene
    action.use_pool = p_use_pool
    action.use_anchor_position = p_use_anchor_position
    action.use_anchor_rotation = p_use_anchor_rotation
    action.random_rotation = p_random_rotation
    action.local_offset = p_local_offset
    action.scatter_radius = p_scatter_radius
    return action
