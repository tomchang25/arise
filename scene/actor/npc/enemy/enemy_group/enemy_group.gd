class_name EnemyGroup
extends Node2D

signal unit_grid_changed
signal group_depleted

@export_group("Group Settings")
@export var size := 10
@export var share_vision: bool = true

@export_group("Wander Settings")
@export var min_wait_time: float = 3.0
@export var max_wait_time: float = 10.0
@export var wander_range: float = 100.0

@export_group("Spawning Logic")
@export var spawn_table: WeightedSpawnTable
@export var spawn_radius: float = 60.0

@onready var wait_timer: Timer = $WaitTimer

var units: Array[Enemy]

## --- GDScript Lifecycle ---


func _ready():
    child_entered_tree.connect(_on_child_entered_tree)
    child_exiting_tree.connect(_on_child_exiting_tree)
    wait_timer.timeout.connect(_on_wait_timer_timeout)

    reset_units()
    reset_wait_timer()

    for child in get_children():
        if child is Enemy:
            add_unit(child)


func spawn_group_members():
    if not spawn_table:
        push_warning("EnemyGroup has no spawn table")
        return

    for i in range(size):
        var mob_scene = spawn_table.get_random_mob()
        if mob_scene:
            var unit = mob_scene.instantiate()
            add_child(unit)

            var spawn_offset = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(spawn_radius / 4, spawn_radius)
            var spawn_position = global_position + spawn_offset
            unit.offset = spawn_offset
            unit.start_position = spawn_position
            unit.next_position = spawn_position

            unit.global_position = spawn_position


func _on_child_entered_tree(child: Node):
    if child is Enemy:
        add_unit(child)


func _on_child_exiting_tree(child: Node):
    if child is Enemy:
        remove_unit(child)


# func _physics_process(_delta):
#     if share_vision:
#         _update_shared_vision()

# func _update_shared_vision() -> void:
#     var all_units = get_all_units()
#     var collective_enemies = []

#     for unit in all_units:
#         if unit.enemy_scanner:
#             for enemy in unit.enemy_scanner.get_internal_enemies():
#                 if not collective_enemies.has(enemy):
#                     collective_enemies.append(enemy)

#     for unit in all_units:
#         if unit.enemy_scanner:
#             unit.enemy_scanner.set_external_enemies(collective_enemies)


func _on_wait_timer_timeout():
    var new_wander_position = generate_random_wander_position(wander_range)
    for unit in get_all_units():
        unit.next_position = new_wander_position + unit.offset

    reset_wait_timer()


func generate_random_wander_position(range_val: float) -> Vector2:
    var random_angle = randf() * TAU
    var random_dist = randf_range(0, range_val)
    return global_position + (Vector2.UP.rotated(random_angle) * random_dist)


## --- Public API ---


func reset_wait_timer() -> void:
    wait_timer.wait_time = randf_range(min_wait_time, max_wait_time)
    wait_timer.start()


func add_unit(unit: Enemy) -> bool:
    var index = get_first_empty_slot()
    if index == -1:
        return false
    unit.offset = unit.global_position - global_position
    units[index] = unit
    unit_grid_changed.emit()
    return true


func remove_unit(unit: Enemy) -> bool:
    var index = units.find(unit)
    if index == -1:
        return false

    units[index] = null
    unit_grid_changed.emit()

    if get_all_units().is_empty():
        group_depleted.emit()
        queue_free()

    return true


func reset_units():
    units.clear()
    for i in range(size):
        units.append(null)
    unit_grid_changed.emit()


func get_first_empty_slot() -> int:
    for i in range(size):
        if units[i] == null:
            return i
    return -1


func get_all_units() -> Array[Enemy]:
    return units.filter(func(unit): return unit != null)

# func is_grid_full() -> bool:
#     return get_first_empty_slot() == -1
