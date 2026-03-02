class_name Placer
extends RefCounted

var spawn_point_scene: PackedScene

func _init(spawn_point_scene_in: PackedScene) -> void:
    spawn_point_scene = spawn_point_scene_in

func place_spawn_point(
    parent: Node,
    at_global_pos: Vector2,
    action: SpawnAction,
    ctx: SpawnContext
) -> SpawnPoint:
    if spawn_point_scene == null:
        push_error("Placer: spawn_point_scene is null")
        return null

    var sp := spawn_point_scene.instantiate() as SpawnPoint
    parent.add_child(sp)
    sp.global_position = at_global_pos
    sp.setup(action, ctx)
    return sp
