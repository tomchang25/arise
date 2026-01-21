extends Node2D

@export var warning_duration: float = 2.5
@onready var warning_sign = $WarningSign  # Sprite2D (Red Cross)
@onready var spawn_timer = $SpawnTimer

var spawn_table: WeightedSpawnTable


func setup_spawner(table: WeightedSpawnTable):
    spawn_table = table


func start_spawn_sequence():
    warning_sign.visible = true
    warning_sign.modulate.a = 0

    var tween = create_tween().set_parallel(true)
    tween.tween_property(warning_sign, "modulate:a", 1.0, warning_duration * 0.5)
    tween.tween_property(warning_sign, "scale", Vector2(1.3, 1.3), warning_duration)

    var rotate_tween = create_tween().set_loops()
    rotate_tween.tween_property(warning_sign, "rotation_degrees", 360, 0.8).from(0)

    spawn_timer.start(warning_duration)
    await spawn_timer.timeout

    rotate_tween.kill()
    warning_sign.visible = false
    spawn_mob()


# func spawn_mob():
#     if not spawn_table:
#         return

#     var group_scene = spawn_table.get_random_mob()
#     if group_scene:
#         var group = group_scene.instantiate()
#         get_parent().add_child(group)
#         group.global_position = global_position
#         queue_free()


func spawn_mob():
    if not spawn_table:
        return

    # In your floor_spawn_table, the 'mob_scene' entries
    # should now be .tres files (EnemyGroupProfile)
    var profile = spawn_table.get_random_mob()

    if profile is EnemyGroupProfile:
        var group = profile.group_scene.instantiate()

        # INJECTION: Set the data while the node is "offline"
        if group is EnemyGroup:
            group.spawn_table = profile.unit_table
            group.size = randi_range(profile.min_size, profile.max_size)

        # Now add it to the world; _ready() will run using the injected values
        get_parent().add_child(group)
        group.global_position = global_position
        group.spawn_group_members()

        queue_free()
    elif profile is PackedScene:
        # Fallback for old behavior (direct scene spawning)
        var instance = profile.instantiate()
        get_parent().add_child(instance)
        instance.global_position = global_position
        queue_free()
