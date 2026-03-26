class_name DirectionalSlotManager
extends Node

## Manages 8 directional slots (N=0, NE=1, E=2, SE=3, S=4, SW=5, W=6, NW=7)
## centered on the Castle at (0,0).
##
## Each slot has two lanes:
##   CLOSED lane — accepts CLOSED groups only, capacity 1
##   RANGED lane — accepts RANGED groups only, capacity 1
##
## Spawn position is sampled along the slot's outward angle within a
## configurable ring (min_radius / max_radius) around the castle.

enum Lane { CLOSED = 0, RANGED = 1 }
enum LaneState { EMPTY, WARNED, OCCUPIED }

const DIRECTION_COUNT := 8

# -------------------------
# Exports
# -------------------------

@export_group("Ring")
## Minimum distance from the castle at which groups spawn.
@export var min_radius: float = 300.0
## Maximum distance from the castle at which groups spawn.
@export var max_radius: float = 500.0

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

# _lane_states[dir_idx][lane] -> LaneState
var _lane_states: Array = []

# _lane_occupants[dir_idx][lane] -> EnemyGroup or null
var _lane_occupants: Array = []

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _lane_states.resize(DIRECTION_COUNT)
    _lane_occupants.resize(DIRECTION_COUNT)
    for i in range(DIRECTION_COUNT):
        _lane_states[i] = [LaneState.EMPTY, LaneState.EMPTY]
        _lane_occupants[i] = [null, null]

# -------------------------
# Public API
# -------------------------


## Assigns the RNG shared with EncounterController for reproducible slot selection.
func set_rng(rng: RandomNumberGenerator) -> void:
    _rng = rng


## Attempts to claim a lane for the given role in any available slot.
##
## Slot selection priority:
##   1. Directions where both lanes are empty (preferred).
##   2. Directions where only the requested lane is empty.
##   Ties within each tier are broken randomly using the encounter RNG.
##
## On success marks the lane as WARNED and returns a Dictionary:
##   { "dir_idx": int, "lane": Lane, "position": Vector2 }
## Returns null when no slot is available for the requested role.
func claim_slot(role: EnemyGroupProfile.GroupRole) -> Variant:
    var lane := _role_to_lane(role)

    var both_empty: Array[int] = []
    var one_empty: Array[int] = []

    for i in range(DIRECTION_COUNT):
        if _lane_states[i][lane] != LaneState.EMPTY:
            continue
        var other := 1 - lane
        if _lane_states[i][other] == LaneState.EMPTY:
            both_empty.append(i)
        else:
            one_empty.append(i)

    var candidates: Array[int]
    if not both_empty.is_empty():
        candidates = both_empty
    elif not one_empty.is_empty():
        candidates = one_empty
    else:
        return null

    var dir_idx := _pick_random(candidates)
    _lane_states[dir_idx][lane] = LaneState.WARNED

    return {
        "dir_idx": dir_idx,
        "lane": lane,
        "position": _compute_spawn_position(dir_idx),
    }


## Promotes a WARNED lane to OCCUPIED once the warning spawn completes.
## No-op if the lane is not currently WARNED.
func mark_occupied(dir_idx: int, lane: Lane, group: EnemyGroup) -> void:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return
    if _lane_states[dir_idx][lane] != LaneState.WARNED:
        return
    _lane_states[dir_idx][lane] = LaneState.OCCUPIED
    _lane_occupants[dir_idx][lane] = group


## Frees a lane when its group is depleted or removed.
func release_slot(dir_idx: int, lane: Lane) -> void:
    if dir_idx < 0 or dir_idx >= DIRECTION_COUNT:
        return
    _lane_states[dir_idx][lane] = LaneState.EMPTY
    _lane_occupants[dir_idx][lane] = null


## Returns true when every lane across all slots is non-empty (WARNED or OCCUPIED).
func all_slots_full() -> bool:
    for i in range(DIRECTION_COUNT):
        for l in range(2):
            if _lane_states[i][l] == LaneState.EMPTY:
                return false
    return true


## Returns the total number of non-empty (WARNED + OCCUPIED) lanes for the given lane type.
func get_total_occupancy(lane: Lane) -> int:
    var count := 0
    for i in range(DIRECTION_COUNT):
        if _lane_states[i][lane] != LaneState.EMPTY:
            count += 1
    return count

# -------------------------
# Internal helpers
# -------------------------


func _role_to_lane(role: EnemyGroupProfile.GroupRole) -> Lane:
    if role == EnemyGroupProfile.GroupRole.RANGED:
        return Lane.RANGED
    return Lane.CLOSED


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
