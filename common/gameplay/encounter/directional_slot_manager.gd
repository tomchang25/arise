class_name DirectionalSlotManager
extends Node

## Manages 8 directional slots (N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7)
## centered on the Castle.
##
## Each direction has three lanes:
##   CLOSED lane — accepts CLOSED groups only, capacity = closed_lane_capacity
##   RANGED lane — accepts RANGED groups only, capacity = ranged_lane_capacity
##   FREE   lane — accepts either role,         capacity = free_lane_capacity
##
## Spawn positions are sampled along the slot's outward angle within a
## configurable ring (min_radius / max_radius) around the castle.
##
## When claiming, the direction with the most combined remaining capacity for
## the requested role is preferred.  Ties are broken randomly.

enum Lane { CLOSED = 0, RANGED = 1, FREE = 2 }
enum LaneState { EMPTY, WARNED, OCCUPIED }

const DIRECTION_COUNT := 8
const LANE_COUNT := 3

# -------------------------
# Exports
# -------------------------

@export_group("Ring")
## Minimum distance from the castle at which groups spawn.
@export var min_radius: float = 300.0
## Maximum distance from the castle at which groups spawn.
@export var max_radius: float = 500.0

@export_group("Lane Capacities")
@export var closed_lane_capacity: int = 2
@export var ranged_lane_capacity: int = 1
@export var free_lane_capacity: int = 2

@export_group("Distances")
## Distance from the castle at which STANDBY groups hold position.
@export var standby_distance: float = 150.0
## Distance from the castle at which ENGAGE groups attack.
@export var engage_distance: float = 50.0
## Informational: approximate spawn radius — EnemyGroup can read this to
## know how far it started from the castle.
@export var hold_distance: float = 300.0

@export_group("Per-Direction Caps")
## Maximum number of groups per direction that may be in STANDBY.
@export var max_standby_per_dir: int = 2
## Maximum number of CLOSED groups per direction that may be in ENGAGE.
@export var max_advancing_closed: int = 2
## Maximum number of RANGED groups per direction that may be in ENGAGE.
@export var max_advancing_ranged: int = 8

@export_group("Global Caps")
## Maximum number of groups across all directions in STANDBY simultaneously.
@export var max_global_standby: int = 8
## Maximum number of groups across all directions in ENGAGE simultaneously.
@export var max_global_engage: int = 4

@export_group("Castle")
## Reference to the Castle node. Position is read at claim time.
@export var castle: Node2D

# -------------------------
# Runtime state
# -------------------------

## Convenience property: current castle world position (falls back to Vector2.ZERO).
var castle_position: Vector2:
    get:
        if is_instance_valid(castle):
            return castle.global_position
        return Vector2.ZERO

var _rng: RandomNumberGenerator

## _lane_states[dir_idx][lane][slot_idx] -> LaneState
var _lane_states: Array = []

## _lane_occupants[dir_idx][lane][slot_idx] -> EnemyGroup or null
var _lane_occupants: Array = []

## _free_lane_roles[dir_idx][slot_idx] -> int  (-1 = unassigned, 0 = CLOSED, 1 = RANGED)
var _free_lane_roles: Array = []

## _standby_count[dir_idx] -> int  (groups in STANDBY for that direction)
var _standby_count: Array = []

## _advancing_count[dir_idx][role_idx] -> int  (groups in ENGAGE for that direction)
var _advancing_count: Array = []

## Global counters across all directions.
var _global_standby_count: int = 0
var _global_engage_count: int = 0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _lane_states.resize(DIRECTION_COUNT)
    _lane_occupants.resize(DIRECTION_COUNT)
    _free_lane_roles.resize(DIRECTION_COUNT)
    _standby_count.resize(DIRECTION_COUNT)
    _advancing_count.resize(DIRECTION_COUNT)

    for i in range(DIRECTION_COUNT):
        _lane_states[i] = [
            _make_state_array(closed_lane_capacity),
            _make_state_array(ranged_lane_capacity),
            _make_state_array(free_lane_capacity),
        ]
        _lane_occupants[i] = [
            _make_null_array(closed_lane_capacity),
            _make_null_array(ranged_lane_capacity),
            _make_null_array(free_lane_capacity),
        ]
        _free_lane_roles[i] = _make_int_array(free_lane_capacity, -1)
        _standby_count[i] = 0
        _advancing_count[i] = [0, 0]  # index 0 = CLOSED, index 1 = RANGED

# -------------------------
# Public API
# -------------------------


## Assigns the RNG shared with EncounterController for reproducible slot selection.
func set_rng(rng: RandomNumberGenerator) -> void:
    _rng = rng


## Attempts to claim a slot for the given role in any available direction.
##
## Direction selection:
##   The direction with the highest combined remaining capacity for the role is
##   preferred (dedicated lane empty slots + unassigned FREE lane empty slots).
##   Ties are broken randomly using the encounter RNG.
##   Within the chosen direction, the dedicated lane is tried first, then FREE.
##
## On success marks the slot as WARNED and returns a Dictionary:
##   { "dir_idx": int, "lane": Lane, "slot_idx": int, "position": Vector2 }
## Returns null when no slot is available for the requested role.
func claim_slot(role: EnemyGroupProfile.GroupRole) -> Variant:
    # Build list of (dir_idx, remaining) for all directions that have capacity.
    var dir_remaining: Array = []
    for i in range(DIRECTION_COUNT):
        var remaining := _remaining_capacity_for_role(i, role)
        if remaining > 0:
            dir_remaining.append([i, remaining])

    if dir_remaining.is_empty():
        return null

    # Find max remaining capacity.
    var max_remaining := 0
    for entry in dir_remaining:
        if entry[1] > max_remaining:
            max_remaining = entry[1]

    # Collect all directions tied at max.
    var best_dirs: Array[int] = []
    for entry in dir_remaining:
        if entry[1] == max_remaining:
            best_dirs.append(entry[0])

    var dir_idx := _pick_random(best_dirs)

    # Try the dedicated lane first.
    var dedicated_lane := _role_to_dedicated_lane(role)
    var dedicated_states: Array = _lane_states[dir_idx][dedicated_lane]
    for s in range(dedicated_states.size()):
        if dedicated_states[s] == LaneState.EMPTY:
            _lane_states[dir_idx][dedicated_lane][s] = LaneState.WARNED
            return {
                "dir_idx": dir_idx,
                "lane": dedicated_lane,
                "slot_idx": s,
                "position": _compute_spawn_position(dir_idx),
            }

    # Fall back to FREE lane.
    var free_states: Array = _lane_states[dir_idx][Lane.FREE]
    var free_roles: Array = _free_lane_roles[dir_idx]
    for s in range(free_states.size()):
        if free_states[s] == LaneState.EMPTY and free_roles[s] == -1:
            _lane_states[dir_idx][Lane.FREE][s] = LaneState.WARNED
            _free_lane_roles[dir_idx][s] = int(role)
            return {
                "dir_idx": dir_idx,
                "lane": Lane.FREE,
                "slot_idx": s,
                "position": _compute_spawn_position(dir_idx),
            }

    # Should not be reached when _remaining_capacity_for_role() is consistent.
    return null


## Promotes a WARNED slot to OCCUPIED once the warning spawn completes.
## No-op if the slot is not currently WARNED.
func mark_occupied(dir_idx: int, lane: Lane, slot_idx: int, group: EnemyGroup) -> void:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return
    var lane_states: Array = _lane_states[dir_idx][lane]
    if slot_idx < 0 or slot_idx >= lane_states.size():
        return
    if lane_states[slot_idx] != LaneState.WARNED:
        return
    _lane_states[dir_idx][lane][slot_idx] = LaneState.OCCUPIED
    _lane_occupants[dir_idx][lane][slot_idx] = group


## Frees a slot when its group is depleted or removed.
func release_slot(dir_idx: int, lane: Lane, slot_idx: int) -> void:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return
    var lane_states: Array = _lane_states[dir_idx][lane]
    if slot_idx < 0 or slot_idx >= lane_states.size():
        return
    _lane_states[dir_idx][lane][slot_idx] = LaneState.EMPTY
    _lane_occupants[dir_idx][lane][slot_idx] = null
    if lane == Lane.FREE:
        _free_lane_roles[dir_idx][slot_idx] = -1


## Returns true when every slot across all lanes and directions is non-empty.
func all_slots_full() -> bool:
    for i in range(DIRECTION_COUNT):
        for lane in range(LANE_COUNT):
            var lane_states: Array = _lane_states[i][lane]
            for s in range(lane_states.size()):
                if lane_states[s] == LaneState.EMPTY:
                    return false
    return true


## Returns the total number of non-empty (WARNED + OCCUPIED) slots for the given lane type.
func get_total_occupancy(lane: Lane) -> int:
    var count := 0
    for i in range(DIRECTION_COUNT):
        var lane_states: Array = _lane_states[i][lane]
        for s in range(lane_states.size()):
            if lane_states[s] != LaneState.EMPTY:
                count += 1
    return count


## Requests permission for a group at dir_idx to enter STANDBY.
## Checks both the per-direction cap and the global standby cap.
## Returns true and increments both counters on success.
## Returns false when either cap is already full.
func request_standby(dir_idx: int) -> bool:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return true
    if _standby_count[dir_idx] >= max_standby_per_dir:
        return false
    if _global_standby_count >= max_global_standby:
        return false
    _standby_count[dir_idx] += 1
    _global_standby_count += 1
    return true


## Notifies that a group at dir_idx has left STANDBY (promoted to ENGAGE or freed).
## Decrements both the per-direction and global standby counters.
func notify_left_standby(dir_idx: int) -> void:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return
    _standby_count[dir_idx] = maxi(_standby_count[dir_idx] - 1, 0)
    _global_standby_count = maxi(_global_standby_count - 1, 0)


## Requests permission for a group at dir_idx to enter ENGAGE.
## Checks per-direction role cap and global engage cap.
## Returns true and increments both counters on success.
## Returns false when either cap is full.
func request_advancing(dir_idx: int, role: EnemyGroupProfile.GroupRole) -> bool:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return true
    var role_idx := int(role)
    var cap: int
    if role == EnemyGroupProfile.GroupRole.CLOSED:
        cap = max_advancing_closed
    else:
        cap = max_advancing_ranged
    if _advancing_count[dir_idx][role_idx] >= cap:
        return false
    if _global_engage_count >= max_global_engage:
        return false
    _advancing_count[dir_idx][role_idx] += 1
    _global_engage_count += 1
    return true


## Notifies that a group at dir_idx has left ENGAGE (depleted, removed, or demoted).
## Decrements both the per-direction and global engage counters.
func notify_left_advancing(dir_idx: int, role: EnemyGroupProfile.GroupRole) -> void:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return
    var role_idx := int(role)
    _advancing_count[dir_idx][role_idx] = maxi(_advancing_count[dir_idx][role_idx] - 1, 0)
    _global_engage_count = maxi(_global_engage_count - 1, 0)

# -------------------------
# Internal helpers
# -------------------------


func _role_to_dedicated_lane(role: EnemyGroupProfile.GroupRole) -> Lane:
    if role == EnemyGroupProfile.GroupRole.RANGED:
        return Lane.RANGED
    return Lane.CLOSED


## Returns the number of slots available for the given role in the given direction.
## Counts empty dedicated-lane slots plus empty unassigned FREE-lane slots.
func _remaining_capacity_for_role(dir_idx: int, role: EnemyGroupProfile.GroupRole) -> int:
    var dedicated_lane := _role_to_dedicated_lane(role)
    var count := 0

    var dedicated: Array = _lane_states[dir_idx][dedicated_lane]
    for s in range(dedicated.size()):
        if dedicated[s] == LaneState.EMPTY:
            count += 1

    var free_states: Array = _lane_states[dir_idx][Lane.FREE]
    var free_roles: Array = _free_lane_roles[dir_idx]
    for s in range(free_states.size()):
        if free_states[s] == LaneState.EMPTY and free_roles[s] == -1:
            count += 1

    return count


## Computes a spawn position along the outward angle of dir_idx,
## sampled within [min_radius, max_radius] around the castle.
## Direction 0 = N (straight up), stepping clockwise by 45° per index.
func _compute_spawn_position(dir_idx: int) -> Vector2:
    var angle := dir_idx * (PI / 4.0) - PI / 2.0
    var radius: float
    if _rng != null:
        radius = _rng.randf_range(min_radius, max_radius)
    else:
        radius = randf_range(min_radius, max_radius)
    return castle_position + Vector2(cos(angle), sin(angle)) * radius


func _pick_random(arr: Array[int]) -> int:
    if arr.size() == 1:
        return arr[0]
    if _rng != null:
        return arr[_rng.randi() % arr.size()]
    return arr[randi() % arr.size()]


func _make_state_array(size: int) -> Array:
    var arr := []
    arr.resize(size)
    arr.fill(LaneState.EMPTY)
    return arr


func _make_null_array(size: int) -> Array:
    var arr := []
    arr.resize(size)
    arr.fill(null)
    return arr


func _make_int_array(size: int, value: int) -> Array:
    var arr := []
    arr.resize(size)
    arr.fill(value)
    return arr
