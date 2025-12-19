class_name ArmyHandler
extends Node2D

signal unit_grid_changed

@export var size := 100
@export var grid_size := 12

@onready var debug_timer: Timer = $DebugTimer

var units: Array[Node]

## --- GDScript Lifecycle ---


func _ready():
    debug_timer.timeout.connect(_on_check_timer_timeout)

    child_entered_tree.connect(_on_child_entered_tree)
    child_exiting_tree.connect(_on_child_exiting_tree)

    reset_units()

    # for i in range(20):
    #     var a = _convert_index_to_grid(i)
    #     print(a)


func _on_child_entered_tree(child: Node):
    if child is CharacterBody2D:
        add_unit(child)


func _on_child_exiting_tree(child: Node):
    if child is CharacterBody2D:
        remove_unit(child)


func _on_check_timer_timeout():
    var armies_state = {&"Follow": 0, &"Chase": 0, &"Idle": 0, &"Attack": 0}
    for army in get_children():
        if army is not CharacterBody2D:
            continue

        var army_current_state = army.get_current_state()
        if army_current_state.name not in armies_state:
            armies_state[army_current_state.name] = 1
        else:
            armies_state[army_current_state.name] += 1

    print(armies_state)


## --- Public API ---


func add_unit(unit: Node) -> bool:
    var index = get_first_empty_slot()

    if index == -1:
        return false

    var grid = _convert_index_to_grid(index)
    var grid_position = grid * grid_size
    unit.grid_position = grid_position
    # print(unit.grid_position)

    units[index] = unit
    unit_grid_changed.emit()

    return true


func remove_unit(unit: Node) -> bool:
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


func get_all_units() -> Array[Node]:
    var temp = units.filter(func(unit): return unit != null)

    return temp


func is_grid_full() -> bool:
    return get_first_empty_slot() == -1


## --- Private ---


func _convert_index_to_grid(index: int) -> Vector2:
    index += 1
    if index <= 0:
        return Vector2.ZERO

    # Determine ring (layer)
    var k = int(ceil((sqrt(index + 1) - 1) / 2))
    var side_len = 2 * k
    var max_index = (2 * k + 1) * (2 * k + 1) - 1
    var offset = max_index - index

    # Right side (going down)
    if offset < side_len:
        return Vector2(k, -k + offset)

    offset -= side_len
    # Bottom side (going left)
    if offset < side_len:
        return Vector2(k - offset, k)

    offset -= side_len
    # Left side (going up)
    if offset < side_len:
        return Vector2(-k, k - offset)

    offset -= side_len
    # Top side (going right)
    return Vector2(-k + offset, -k)
