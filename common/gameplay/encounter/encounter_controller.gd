class_name EncounterController
extends Node

signal group_spawned(group: EnemyGroup)
signal group_depleted(group: EnemyGroup)
signal encounter_cleared

@export_group("Dependencies")
@export var enemies_root: Node2D
@export var despawn_manager: DespawnController

@export_group("Warning Spawn")
@export var warning_point_scene: PackedScene = preload("uid://djodnob72wufg")

@export_group("Debug")
@export var print_debug_log := false

var _active_groups: Array[EnemyGroup] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    _rng.randomize()


# -------------------------
# Public API
# -------------------------


# Spawns all groups from a profile at or around origin.
# positions: optional override array — one position per group in profile order.
# If fewer positions than groups, remaining groups reuse the last position.
func spawn_encounter(profile: EncounterProfile, origin: Vector2, positions: Array[Vector2] = []) -> void:
    if not _validate_profile(profile):
        return

    var valid_groups := profile.get_valid_groups()

    for i in range(valid_groups.size()):
        var group_profile := valid_groups[i]
        var spawn_pos := positions[i] if i < positions.size() else (positions[-1] if not positions.is_empty() else origin)
        _spawn_group(group_profile, spawn_pos)


# Spawns a single group at a position — useful for injecting elites mid-encounter.
func add_group(group_profile: EnemyGroupProfile, position: Vector2) -> void:
    if not _validate_group_profile(group_profile):
        return

    _spawn_group(group_profile, position)


# Clears all active groups and spawns a new encounter profile.
func transition_to(profile: EncounterProfile, origin: Vector2, positions: Array[Vector2] = []) -> void:
    clear_all_groups()
    spawn_encounter(profile, origin, positions)


# Queue-frees all active groups immediately.
func clear_all_groups() -> void:
    for group in _active_groups:
        if is_instance_valid(group):
            group.queue_free()

    _active_groups.clear()


func get_active_group_count() -> int:
    _cleanup_invalid()
    return _active_groups.size()


func get_active_member_count() -> int:
    _cleanup_invalid()
    var total := 0
    for group in _active_groups:
        if is_instance_valid(group):
            total += group.get_member_count()
    return total


func is_cleared() -> bool:
    _cleanup_invalid()
    return _active_groups.is_empty()


# -------------------------
# Internal
# -------------------------


# Internal — always async due to warning flow.
func _spawn_group(group_profile: EnemyGroupProfile, position: Vector2) -> void:
    if warning_point_scene == null:
        Debug.warn("EncounterController: warning_point_scene is null — assign it in the editor")
        return

    if not is_instance_valid(enemies_root):
        Debug.warn("EncounterController: enemies_root is null or freed")
        return

    var action := SpawnEnemyGroupAction.new()
    action.profile = group_profile

    var ctx := SpawnContext.new()
    ctx.setup(enemies_root, _rng.randi(), self)

    var spawned := await SpawnWarningExecutor.execute_at_position(warning_point_scene, action, position, ctx)

    if not is_instance_valid(self):
        return

    var group := spawned as EnemyGroup
    if group == null:
        Debug.warn("EncounterController: warning spawn did not return an EnemyGroup")
        return

    _active_groups.append(group)
    group.group_depleted.connect(_on_group_depleted.bind(group))

    if despawn_manager != null:
        despawn_manager.register_spawned(group)

    group_spawned.emit(group)

    if print_debug_log:
        Debug.log("EncounterController: spawned group '%s' at %s with %s members" % [group_profile.resource_name, position, group.get_member_count()])


func _on_group_depleted(group: EnemyGroup) -> void:
    var idx := _active_groups.find(group)
    if idx != -1:
        _active_groups.remove_at(idx)

    group_depleted.emit(group)

    if print_debug_log:
        Debug.log("EncounterController: group depleted, remaining=%s" % _active_groups.size())

    if _active_groups.is_empty():
        encounter_cleared.emit()


func _cleanup_invalid() -> void:
    _active_groups = _active_groups.filter(func(g): return is_instance_valid(g))


func _validate_profile(profile: EncounterProfile) -> bool:
    if profile == null:
        Debug.warn("EncounterController: profile is null")
        return false

    if not profile.is_valid():
        Debug.warn("EncounterController: profile has no valid groups")
        return false

    return true


func _validate_group_profile(group_profile: EnemyGroupProfile) -> bool:
    if group_profile == null:
        Debug.warn("EncounterController: group_profile is null")
        return false

    if not group_profile.is_valid():
        Debug.warn("EncounterController: group_profile is invalid")
        return false

    return true
