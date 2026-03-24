class_name SummonManager
extends Node

signal counts_changed(type_index: int, current: int, max_count: int)
signal souls_changed(souls: int)
signal active_group_changed(group_index: int)
signal group_count_changed(group_index: int, count: int)

@export var army_types: Array[SummonType] = []
@export var debug_starting_souls: int = 0

## Container node where spawned Army units will be added as children.
## If null, units are added to the current scene root.
@export var armies_container: Node

var group_count := 0

var _player: Player

var _groups: Array
var _counts: Array[int] = []
var _tracked_units: Array = [] # Array of Arrays, one per type
var _active_group_index: int = 0


func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")
    _groups = get_tree().get_nodes_in_group("army_group")
    _groups.sort_custom(func(a, b): return a.group_id < b.group_id)

    group_count = _groups.size()
    for i in group_count:
        _groups[i].unit_grid_changed.connect(_on_group_count_changed.bind(i))

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
    # 1–4: select active group
    for i in 4:
        if event.is_action_pressed("summon_%d" % (i + 1)):
            _set_active_group(i)
            return
    # F1–F4: summon type to active group
    if event is InputEventKey and event.pressed and not event.echo:
        match event.physical_keycode:
            KEY_F1:
                summon(0)
            KEY_F2:
                summon(1)
            KEY_F3:
                summon(2)
            KEY_F4:
                summon(3)

# -------------------------
# Public API
# -------------------------


func summon(type_index: int) -> bool:
    if type_index < 0 or type_index >= army_types.size():
        return false

    if _active_group_index >= _groups.size():
        return false

    var army_type: SummonType = army_types[type_index]

    if _counts[type_index] >= army_type.max_count:
        return false

    if _player == null or not _player.stats.spend_souls(army_type.soul_cost):
        return false

    var active_group: ArmyGroup = _groups[_active_group_index]
    if army_type.scene == null or active_group == null:
        return false

    # --- Spawn the unit ---
    var spawn_action := SpawnPackedSceneAction.create(army_type.scene)
    spawn_action.use_pool = true

    # Determine the container: use armies_container if set, otherwise current scene root.
    var container: Node = armies_container if armies_container else get_tree().current_scene

    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(container, 0, _player, { })

    var unit := SpawnExecutor.execute_at_position(spawn_action, _player.global_position, spawn_ctx) as Army
    if unit == null:
        return false

    unit.modulate = army_type.color

    # --- Register with the active group instead of parenting ---
    # register_member() assigns the formation slot and sets anchor_position.
    active_group.register_member(unit, _player.global_position)

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


func get_active_group() -> int:
    return _active_group_index


func get_group_count(group_index: int) -> int:
    if group_index >= _groups.size():
        return 0
    return _groups[group_index].get_unit_count()

# -------------------------
# Private
# -------------------------


func _set_active_group(index: int) -> void:
    if index < 0 or index >= _groups.size():
        return
    _active_group_index = index
    active_group_changed.emit(_active_group_index)


func _on_group_count_changed(group_index: int) -> void:
    group_count_changed.emit(group_index, get_group_count(group_index))


func _on_unit_removed(type_index: int, unit: Node) -> void:
    _tracked_units[type_index].erase(unit)
    _counts[type_index] = maxi(0, _counts[type_index] - 1)
    counts_changed.emit(type_index, _counts[type_index], army_types[type_index].max_count)


func _on_souls_changed(new_souls: int) -> void:
    souls_changed.emit(new_souls)
