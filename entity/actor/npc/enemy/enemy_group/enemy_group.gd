class_name EnemyGroup
extends Node2D

signal unit_grid_changed

@export var size := 100
@export var grid_size := 12
@export var share_vision: bool = true

@export var min_wait_time: float = 3.0
@export var max_wait_time: float = 10.0

@export var spawn_range: Vector2 = Vector2(50, 50)

@onready var wait_timer: Timer = $WaitTimer

var units: Array[Enemy]

## --- GDScript Lifecycle ---


func _ready():
    child_entered_tree.connect(_on_child_entered_tree)
    child_exiting_tree.connect(_on_child_exiting_tree)

    wait_timer.timeout.connect(_on_wait_timer_timeout)
    reset_wait_timer()
    reset_units()

    # TODO : Temporary
    for child in get_children():
        if child is Enemy:
            add_unit(child)


func _on_child_entered_tree(child: Node):
    if child is Enemy:
        add_unit(child)


func _on_child_exiting_tree(child: Node):
    if child is Enemy:
        remove_unit(child)


func _physics_process(_delta):
    if share_vision:
        _update_shared_vision()


func _update_shared_vision() -> void:
    var all_units = get_all_units()
    var collective_enemies = []

    # 1. Collect all enemies seen by every unit's local detectbox
    for unit in all_units:
        if unit.enemy_scanner:
            for enemy in unit.enemy_scanner.get_internal_enemies():
                if not collective_enemies.has(enemy):
                    collective_enemies.append(enemy)

    # 2. Distribute the collective list back to every scanner
    for unit in all_units:
        if unit.enemy_scanner:
            unit.enemy_scanner.set_external_enemies(collective_enemies)


func _on_wait_timer_timeout():
    var new_wander_position = generate_random_wander_position()
    for unit in get_all_units():
        unit.next_position = new_wander_position + unit.offset

    print("Group, new wander position: ", new_wander_position)

    reset_wait_timer()


func generate_random_wander_position(wander_range: float = 250) -> Vector2:
    var random_angle = randf() * TAU
    var random_dist = randf_range(0, wander_range)

    var travel_vector = Vector2.UP.rotated(random_angle) * random_dist
    var candidate_position = global_position + travel_vector

    return candidate_position


## --- Public API ---


func reset_wait_timer() -> void:
    wait_timer.wait_time = randf_range(min_wait_time, max_wait_time)


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
    var temp = units.filter(func(unit): return unit != null)
    return temp


func is_grid_full() -> bool:
    return get_first_empty_slot() == -1

## --- Private ---

# func _convert_index_to_grid(index: int) -> Vector2:
#     index += 1
#     if index <= 0:
#         return Vector2.ZERO

#     # Determine ring (layer)
#     var k = int(ceil((sqrt(index + 1) - 1) / 2))
#     var side_len = 2 * k
#     var max_index = (2 * k + 1) * (2 * k + 1) - 1
#     var offset = max_index - index

#     # Right side (going down)
#     if offset < side_len:
#         return Vector2(k, -k + offset)

#     offset -= side_len
#     # Bottom side (going left)
#     if offset < side_len:
#         return Vector2(k - offset, k)

#     offset -= side_len
#     # Left side (going up)
#     if offset < side_len:
#         return Vector2(-k, k - offset)

#     offset -= side_len
#     # Top side (going right)
#     return Vector2(-k + offset, -k)
