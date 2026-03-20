class_name SummonManager
extends Node

signal counts_changed(type_index: int, current: int, max_count: int)
signal souls_changed(souls: int)

@export var army_types: Array[SummonType] = []
@export var debug_starting_souls: int = 0

var _player: Player
var _army_handler: ArmyHandler
var _counts: Array[int] = []
var _tracked_units: Array = []  # Array of Arrays, one per type


func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")
    _army_handler = get_tree().get_first_node_in_group("army_handler")

    _counts.resize(army_types.size())
    _counts.fill(0)
    _tracked_units.resize(army_types.size())
    for i in army_types.size():
        _tracked_units[i] = []

    if _player and _player.stats:
        _player.stats.souls_changed.connect(_on_souls_changed)
        if debug_starting_souls > 0:
            _player.stats.add_souls(debug_starting_souls)


func _unhandled_input(event: InputEvent) -> void:
    for i in army_types.size():
        if event.is_action_pressed("summon_%d" % (i + 1)):
            summon(i)


# -------------------------
# Public API
# -------------------------


func summon(type_index: int) -> bool:
    if type_index < 0 or type_index >= army_types.size():
        return false

    var army_type: SummonType = army_types[type_index]

    if _counts[type_index] >= army_type.max_count:
        return false

    if _player == null or not _player.stats.spend_souls(army_type.soul_cost):
        return false

    if army_type.scene == null or _army_handler == null:
        return false

    var unit = army_type.scene.instantiate()
    unit.modulate = army_type.color
    _army_handler.add_child(unit)
    unit.global_position = _player.global_position

    _tracked_units[type_index].append(unit)
    _counts[type_index] += 1
    counts_changed.emit(type_index, _counts[type_index], army_type.max_count)

    unit.tree_exiting.connect(_on_unit_removed.bind(type_index, unit))

    return true


func get_souls() -> int:
    if _player and _player.stats:
        return _player.stats.souls
    return 0


func get_count(type_index: int) -> int:
    if type_index < _counts.size():
        return _counts[type_index]
    return 0


func get_max(type_index: int) -> int:
    if type_index < army_types.size():
        return army_types[type_index].max_count
    return 0


func get_cost(type_index: int) -> int:
    if type_index < army_types.size():
        return army_types[type_index].soul_cost
    return 0


# -------------------------
# Private
# -------------------------


func _on_unit_removed(type_index: int, unit: Node) -> void:
    _tracked_units[type_index].erase(unit)
    _counts[type_index] = maxi(0, _counts[type_index] - 1)
    counts_changed.emit(type_index, _counts[type_index], army_types[type_index].max_count)


func _on_souls_changed(new_souls: int) -> void:
    souls_changed.emit(new_souls)
