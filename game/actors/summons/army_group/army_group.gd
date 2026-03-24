@tool
class_name ArmyGroup
extends Node2D

## Emitted whenever the member list or slot changes (for UI / minimap).
signal unit_grid_changed

enum FormationType { RECTANGULAR, CIRCULAR }

# -------------------------
# Exports — Formation
# -------------------------

@export var group_id: int
@export var size := 100
@export var grid_size := 12
@export var formation_type: FormationType = FormationType.RECTANGULAR

## When enabled, the anchor is updated to the player's world position every
## [member track_interval] seconds. When disabled, the anchor stays wherever
## it was last set.
@export var track_player: bool = true

## Seconds between automatic anchor updates when [member track_player] is true.
## Set to 0 to update every physics frame.
@export var track_interval: float = 0.05

# -------------------------
# Exports — Aggro
# -------------------------

## Detection area used for target acquisition — set radius to desired aggro range in scene.
@export var detection_module: DetectionModule

## Distance from group center at which members aggro nearby enemies.
@export var aggro_range: float = 120.0

## Distance at which members deaggro. Should be larger than aggro_range.
@export var deaggro_range: float = 160.0

## Maximum distance the group center may stray from the anchor before members
## are forced back. Set to 0 to disable leashing entirely.
@export var leash_distance: float = 200.0

# -------------------------
# Internal state
# -------------------------

## Slot array — null means the slot is empty, otherwise holds the registered Army unit.
var units: Array[Node]

## The logical anchor position used to compute each unit's formation slot.
## Stored as a plain Vector2 so changing it does NOT move this Node2D.
var _anchor: Vector2 = Vector2.ZERO

## Per-unit grid offsets in world units, keyed by unit node.
## Populated in register_member(), cleared on unit death / removal.
var _unit_offsets: Dictionary = { }

## Accumulated time for periodic anchor updates.
var _track_timer: float = 0.0

## Accumulated time for position update (every POSITION_UPDATE_INTERVAL seconds).
var _position_timer: float = 0.0
const POSITION_UPDATE_INTERVAL := 0.1

## Player reference — resolved at _ready().
var _player: Node2D

## Aggro state — set by _update_aggro_state(), pushed to all members.
var _aggroed: bool = false
var _aggro_timer: float = 0.0
const AGGRO_CHECK_INTERVAL := 0.1

var _returning_to_spawn: bool = false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _player = get_tree().get_first_node_in_group("player")

    if not detection_module:
        detection_module = find_child("DetectionModule", true, false) as DetectionModule

    if detection_module:
        detection_module.radius = deaggro_range

    reset_units()

    if _player:
        _anchor = _player.global_position


func _physics_process(delta: float) -> void:
    # Sync anchor to player position.
    if track_player and _player:
        if track_interval <= 0.0:
            set_anchor(_player.global_position)
        else:
            _track_timer += delta
            if _track_timer >= track_interval:
                _track_timer = 0.0
                set_anchor(_player.global_position)

    # Update group node position to living member centroid.
    _position_timer += delta
    if _position_timer >= POSITION_UPDATE_INTERVAL:
        _position_timer = 0.0
        var alive := get_all_units()
        if not alive.is_empty():
            global_position = _get_center(alive)

        # Leash check runs after position update so global_position is current.
        _check_leash()

        if _returning_to_spawn:
            if global_position.distance_to(_anchor) < (leash_distance / 4.0):
                _returning_to_spawn = false

    # Aggro check.
    _aggro_timer += delta
    if _aggro_timer >= AGGRO_CHECK_INTERVAL:
        _aggro_timer = 0.0
        _update_aggro_state()

# -------------------------
# Member registry
# -------------------------


## Register [param unit] with this group at a formation slot near [param setup_position].
## The unit's scene-tree parent is managed externally — this only stores the reference.
func register_member(unit: Army, setup_position: Vector2 = Vector2.ZERO) -> bool:
    # Reject if already registered.
    for i in size:
        if units[i] == unit:
            return false

    var index := get_first_empty_slot()
    if index == -1:
        return false

    # Place unit at its formation slot.
    var grid := _convert_index_to_grid(index)
    var offset := grid * grid_size
    _unit_offsets[unit] = offset

    unit.global_position = setup_position
    unit.anchor_position = _anchor + offset

    units[index] = unit
    unit_grid_changed.emit()

    # Listen for removal so the slot is freed automatically.
    if not unit.tree_exiting.is_connected(_on_unit_exiting_tree.bind(unit)):
        unit.tree_exiting.connect(_on_unit_exiting_tree.bind(unit))

    return true


## Manually unregister [param unit] from this group without freeing it.
func unregister_member(unit: Army) -> bool:
    return _remove_unit(unit)

# -------------------------
# Public API — anchor / formation
# -------------------------


## Moves the formation anchor to [param new_position] and immediately updates
## every unit's anchor_position. Does NOT move the Node2D itself.
func set_anchor(new_position: Vector2) -> void:
    _anchor = new_position
    for unit in get_all_units():
        var offset: Vector2 = _unit_offsets.get(unit, Vector2.ZERO)
        unit.anchor_position = _anchor + offset


func get_first_empty_slot() -> int:
    for i in range(size):
        if units[i] == null:
            return i
    return -1


func get_all_units() -> Array[Node]:
    var result: Array[Node] = []
    for u in units:
        if u != null and is_instance_valid(u):
            result.append(u)
    return result


func get_unit_count() -> int:
    return get_all_units().size()


func is_grid_full() -> bool:
    return get_first_empty_slot() == -1


func reset_units() -> void:
    units.clear()
    _unit_offsets.clear()
    for i in range(size):
        units.append(null)
    unit_grid_changed.emit()


## Changes the active formation type and re-assigns grid positions for all
## current units so the formation takes effect immediately.
func set_formation_type(type: FormationType) -> void:
    formation_type = type
    _rebuild_formation()

# -------------------------
# Internal — formation
# -------------------------


func _rebuild_formation() -> void:
    var all_units := get_all_units()
    for i in range(size):
        units[i] = null
    _unit_offsets.clear()

    for unit in all_units:
        var index := get_first_empty_slot()
        if index == -1:
            break
        var grid := _convert_index_to_grid(index)
        var offset := grid * grid_size
        _unit_offsets[unit] = offset
        unit.anchor_position = _anchor + offset
        units[index] = unit

    unit_grid_changed.emit()


func _remove_unit(unit: Node) -> bool:
    var index := units.find(unit)
    if index == -1:
        return false

    units[index] = null
    _unit_offsets.erase(unit)
    unit_grid_changed.emit()
    return true


func _get_center(alive: Array[Node]) -> Vector2:
    var sum := Vector2.ZERO
    for u in alive:
        sum += (u as Node2D).global_position
    return sum / float(alive.size())

# -------------------------
# Internal — aggro
# -------------------------


func _update_aggro_state() -> void:
    if detection_module == null:
        return

    if _returning_to_spawn:
        return

    if not _aggroed:
        # Aggro when any enemy enters aggro_range of the group center.
        var nearest := _get_nearest_enemy()
        if nearest != null:
            var dist := nearest.global_position.distance_squared_to(global_position)
            if dist < aggro_range * aggro_range:
                _aggroed = true
                _assign_targets_to_members()
    else:
        # Deaggro when no targets remain in detection (deaggro) range.
        var target := detection_module.get_closest_target(false)
        if target == null:
            _aggroed = false
            for unit in get_all_units():
                (unit as Army).group_aggroed = false
                (unit as Army).group_target = null
        else:
            # Re-assign each tick so members switch to a closer target if one appears.
            _assign_targets_to_members()


func _check_leash() -> void:
    if leash_distance <= 0.0:
        return

    if global_position.distance_to(_anchor) <= leash_distance:
        return

    _aggroed = false
    _returning_to_spawn = true
    for unit in get_all_units():
        var army := unit as Army
        army.group_aggroed = false
        army.group_target = null


func _assign_targets_to_members() -> void:
    var targets: Array[Node2D] = detection_module.get_targets(false) if detection_module else []
    for unit in get_all_units():
        var army := unit as Army
        army.group_aggroed = true
        army.group_target = _get_closest_target_to(army.global_position, targets)


func _get_nearest_enemy() -> Node2D:
    # Use detection_module targets if already available; otherwise fall back to
    # a manual distance check against all enemies in the scene.
    if detection_module:
        return detection_module.get_closest_target(false)

    var enemies := get_tree().get_nodes_in_group("enemies")
    var closest: Node2D = null
    var min_dist_sq := INF
    for e in enemies:
        if not is_instance_valid(e):
            continue
        var d := (e as Node2D).global_position.distance_squared_to(global_position)
        if d < min_dist_sq:
            min_dist_sq = d
            closest = e as Node2D
    return closest


func _get_closest_target_to(origin: Vector2, targets: Array[Node2D]) -> Node2D:
    var closest: Node2D = null
    var min_dist_sq := INF
    for target in targets:
        if not is_instance_valid(target):
            continue
        var d := origin.distance_squared_to(target.global_position)
        if d < min_dist_sq:
            min_dist_sq = d
            closest = target
    return closest

# -------------------------
# Callbacks
# -------------------------


func _on_unit_exiting_tree(unit: Node) -> void:
    _remove_unit(unit)

# -------------------------
# Formation math (unchanged)
# -------------------------


func _convert_index_to_grid(index: int) -> Vector2:
    match formation_type:
        FormationType.CIRCULAR:
            return _convert_index_to_circular(index)
        _:
            return _convert_index_to_rectangular(index)


## Rectangular (spiral) formation — original algorithm.
## Positions units in a square spiral expanding outward from the centre.
func _convert_index_to_rectangular(index: int) -> Vector2:
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


## Circular (ring-based) formation — new algorithm.
## Places the first unit at the centre, then fills concentric rings of 6·k
## evenly-spaced slots at radius k, expanding outward.
##
## Ring 0: 1 slot  (index 0)
## Ring 1: 6 slots (indices 1-6)
## Ring 2: 12 slots (indices 7-18)
## Ring k: 6·k slots; total through ring k = 1 + 3·k·(k+1)
##
## Returned coordinates are in grid-cell units; multiply by grid_size for
## world-space offsets.
func _convert_index_to_circular(index: int) -> Vector2:
    if index == 0:
        return Vector2.ZERO

    # Find the ring number k (smallest k where total slots through ring k > index).
    # Total T(k) = 1 + 3·k·(k+1).  Solving T(k) > index:
    #   3k² + 3k > index - 1  →  k > (-3 + sqrt(9 + 12·(index-1))) / 6
    var k := int(floor((-3.0 + sqrt(9.0 + 12.0 * float(index - 1))) / 6.0)) + 1

    # First slot index of ring k.
    var ring_start := 1 + 3 * (k - 1) * k
    var pos_in_ring := index - ring_start

    # Evenly distribute within the ring.
    var angle := pos_in_ring * TAU / float(6 * k)
    return Vector2(cos(angle) * k, sin(angle) * k)
