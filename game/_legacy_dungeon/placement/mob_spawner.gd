class_name MobSpawner
extends Node2D

signal group_spawned(group: Node)

@export var warning_duration: float = 2.5
@export var enemy_group_scene: PackedScene  # set to your EnemyGroup.tscn

@onready var warning_sign: AnimatedSprite2D = $WarningSign
@onready var spawn_timer: Timer = $SpawnTimer

# @export var spawn_table: WeightedSpawnTable

var encounter_table: WeightedEncounterTable
var rng: RandomNumberGenerator
var spawn_root: Node


func setup_spawner(table: WeightedEncounterTable, _rng: RandomNumberGenerator = null, _spawn_root := get_parent()) -> void:
    encounter_table = table
    rng = _rng
    spawn_root = _spawn_root


func start_spawn_sequence() -> void:
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

    _spawn_group()
    queue_free()


func _spawn_group() -> void:
    if encounter_table == null:
        push_warning("mob_spawner: encounter_table is null")
        return
    if enemy_group_scene == null:
        push_warning("mob_spawner: enemy_group_scene is null")
        return

    var profile := encounter_table.pick(rng)
    if profile == null:
        push_warning("mob_spawner: encounter_table returned null")
        return

    var group := enemy_group_scene.instantiate()
    # IMPORTANT: set position BEFORE adding so deferred spawn uses correct position
    group.global_position = global_position
    group.encounter_profile = profile

    spawn_root.add_child(group)
    group_spawned.emit(group)

# func _spawn_group() -> void:
#     if spawn_table == null:
#         push_warning("mob_spawner: spawn_table is null")
#         return

#     var picked := spawn_table.get_random_mob(rng)
#     if picked == null:
#         push_warning("mob_spawner: table returned null")
#         return

#     if not (picked is EnemyGroupProfile):
#         push_warning("mob_spawner: expected EnemyGroupProfile, got: %s" % [picked])
#         return

#     var profile: EnemyGroupProfile = picked
#     if profile.group_scene == null:
#         push_warning("mob_spawner: profile.group_scene is null")
#         return

#     var group := profile.group_scene.instantiate()
#     get_parent().add_child(group)
#     group.global_position = global_position

#     if group.has_method("setup_profile"):
#         group.call("setup_profile", profile, rng)
#     else:
#         push_warning("mob_spawner: group scene missing setup_profile(profile, rng)")

# func spawn_mob():
#     if not spawn_table:
#         return

#     # In your floor_spawn_table, the 'mob_scene' entries
#     # should now be .tres files (EnemyGroupProfile)
#     var profile = spawn_table.get_random_mob()

#     if profile is EnemyGroupProfile:
#         var group = profile.group_scene.instantiate()

#         # INJECTION: Set the data while the node is "offline"
#         if group is EnemyGroup:
#             group.spawn_table = profile.unit_table
#             group.size = randi_range(profile.min_size, profile.max_size)

#         # Now add it to the world; _ready() will run using the injected values
#         get_parent().add_child(group)
#         group.global_position = global_position
#         group.spawn_group_members()

#         queue_free()
#     elif profile is PackedScene:
#         # Fallback for old behavior (direct scene spawning)
#         var instance = profile.instantiate()
#         get_parent().add_child(instance)
#         instance.global_position = global_position
#         queue_free()
