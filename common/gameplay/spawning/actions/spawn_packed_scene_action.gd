class_name SpawnPackedSceneAction
extends SpawnAction

@export var scene: PackedScene

@export_group("Parent")
@export var parent_mode: ParentMode = ParentMode.CTX_SPAWN_PARENT
@export var parent_path: NodePath
@export var parent_group: String = ""

@export_group("Transform")
@export var use_anchor_position: bool = true
@export var use_anchor_rotation: bool = false
@export var random_rotation: bool = false

@export_group("Offset")
@export var local_offset: Vector2 = Vector2.ZERO
@export var scatter_radius: float = 0.0


func execute(anchor: Node2D, ctx: SpawnContext) -> Node:
    if scene == null:
        Debug.warn("SpawnPackedSceneAction: scene is null")
        return null

    if anchor == null:
        Debug.warn("SpawnPackedSceneAction: anchor is null")
        return null

    var parent := resolve_parent(anchor, ctx, parent_mode, parent_path, parent_group)
    if parent == null:
        Debug.warn("SpawnPackedSceneAction: parent is null")
        return null

    var instance := scene.instantiate()
    if instance == null:
        Debug.warn("SpawnPackedSceneAction: failed to instantiate scene")
        return null

    parent.call_deferred("add_child", instance)

    if instance is Node2D:
        var node_2d := instance as Node2D
        var rng := ctx.get_rng() if ctx != null else null

        var target_position := anchor.global_position

        if local_offset != Vector2.ZERO:
            target_position += local_offset.rotated(anchor.global_rotation)

        if scatter_radius > 0.0:
            target_position += SpatialRandomUtils.random_point_in_circle(Vector2.ZERO, scatter_radius, rng)

        if use_anchor_position:
            node_2d.global_position = target_position

        if random_rotation:
            node_2d.global_rotation = _random_rotation(rng)
        elif use_anchor_rotation:
            node_2d.global_rotation = anchor.global_rotation

    return instance


func _random_rotation(rng: RandomNumberGenerator = null) -> float:
    if rng != null:
        return rng.randf_range(0.0, TAU)

    var fallback_rng := RandomNumberGenerator.new()
    fallback_rng.randomize()
    return fallback_rng.randf_range(0.0, TAU)
