class_name EnemyGroup
extends Node2D

signal unit_grid_changed
signal group_depleted

@export_group("Group Settings")
@export var share_vision: bool = true

@export_group("Wander Settings")
@export var min_wait_time: float = 3.0
@export var max_wait_time: float = 10.0
@export var wander_range: float = 100.0

@export_group("Spawning Logic")
@export var encounter_profile: EnemyEncounterProfile:
    set(value):
        encounter_profile = value
        # if already in tree, schedule spawn
        if is_inside_tree() and encounter_profile != null:
            _schedule_spawn()

# @export var spawn_table: WeightedSpawnTable
# @export var spawn_radius: float = 60.0
# @export var size := 10

var units: Array[Enemy]
var _rng: RandomNumberGenerator = null
var _spawned := false
var _target_size := 0


func _ready():
    child_entered_tree.connect(_on_child_entered_tree)
    child_exiting_tree.connect(_on_child_exiting_tree)

    _rng = RandomNumberGenerator.new()
    _rng.randomize()

    # If placed in editor with an encounter_profile assigned:
    if encounter_profile != null:
        _schedule_spawn()
    else:
        # Still initialize internal storage
        _reset_units(0)

    # reset_units()
    # for child in get_children():
    #     if child is Enemy:
    #         add_unit(child)


# ---------------------------
# Spawning
# ---------------------------
func _schedule_spawn() -> void:
    # Prevent double spawn if profile is set twice
    if _spawned:
        return
    _spawned = true

    # Defer so global_position is already correct (spawner can set it before add_child)
    call_deferred("_spawn_members_from_profile")


func _spawn_members_from_profile() -> void:
    if encounter_profile == null:
        push_warning("EnemyGroup: encounter_profile is null")
        return

    _target_size = _rng.randi_range(encounter_profile.min_size, encounter_profile.max_size)
    _reset_units(_target_size)

    var entries := encounter_profile.unit_entries
    if entries.is_empty():
        push_warning("EnemyGroup: encounter_profile.unit_entries is empty")
        return

    for i in range(_target_size):
        var scene := _pick_unit_scene(entries)
        if scene == null:
            continue

        var ang := _rng.randf_range(0.0, TAU)
        var dist := _rng.randf_range(encounter_profile.spawn_radius * 0.25, encounter_profile.spawn_radius)
        var spawn_pos := global_position + Vector2.RIGHT.rotated(ang) * dist

        var unit := scene.instantiate() as Enemy
        unit.home_position = spawn_pos
        add_child(unit)

        # # Robust spawn init (prevents home_position=0,0)
        # if unit.has_method("setup_spawn"):
        #     unit.call("setup_spawn", spawn_pos)
        # else:
        #     unit.global_position = spawn_pos
        #     if "home_position" in unit:
        #         unit.home_position = spawn_pos


func _pick_unit_scene(entries: Array[WeightedSceneEntry]) -> PackedScene:
    var total := 0
    for e in entries:
        total += max(0, e.weight)
    if total <= 0:
        return null

    var roll := _rng.randi_range(1, total)
    var acc := 0
    for e in entries:
        acc += max(0, e.weight)
        if roll <= acc:
            return e.scene

    return null


func _on_child_entered_tree(child: Node):
    if child is Enemy:
        _add_unit(child)


func _on_child_exiting_tree(child: Node):
    if child is Enemy:
        _remove_unit(child)


func _reset_units(size: int) -> void:
    units.clear()
    for i in range(size):
        units.append(null)
    unit_grid_changed.emit()


func _add_unit(unit: Enemy) -> void:
    for i in range(units.size()):
        if units[i] == null:
            units[i] = unit
            unit_grid_changed.emit()
            return


func _remove_unit(unit: Enemy) -> void:
    var idx := units.find(unit)
    if idx != -1:
        units[idx] = null
        unit_grid_changed.emit()

    # Group depleted check
    var any_alive := false
    for u in units:
        if u != null:
            any_alive = true
            break

    if not any_alive:
        group_depleted.emit()
        queue_free()
