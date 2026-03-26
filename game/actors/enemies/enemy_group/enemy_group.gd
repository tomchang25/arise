class_name EnemyGroup
extends Node2D

## Emitted when every member died via their died signal — player cleared the group.
signal group_depleted

## Emitted when the group is removed for any other reason — despawn, queue_free, etc.
signal group_removed

## Emitted whenever the member list changes (for minimap or UI).
signal members_changed

enum FormationType { NONE, RECTANGULAR, CIRCULAR }

## Three-state pressure machine that governs how the group advances on the castle.
enum PressureState { ADVANCING, HOLDING, ATTACKING }

# -------------------------
# Exports — Anchor tracking
# -------------------------

@export var dormant_distance: float = 960.0
@export var dormant_check_interval: float = 1.0

## Distance from group center at which members aggro the player.
@export var aggro_range: float = 240.0

## Distance from group center at which members deaggro.
## Should be larger than aggro_range to prevent oscillation.
@export var deaggro_range: float = 320.0

## Detection area used for aggro targeting and deaggro — wired in scene.
## Radius is set to deaggro_range in _ready().
@export var detection_module: DetectionModule

## Maximum distance any member may stray from spawn_pivot before being
## forced back home. Set to 0 to disable leashing entirely.
@export var leash_distance: float = 300.0

# -------------------------
# Exports — Formation
# -------------------------

## Formation layout applied to registered members.
## NONE keeps the random scatter positions set by the spawner.
## RECTANGULAR and CIRCULAR assign slot-based grid offsets.
@export var formation_type: FormationType = FormationType.NONE

## World-space distance between adjacent formation slots (grid cell size).
@export var grid_size: int = 16

## Speed (units/sec) at which target_position creeps toward the castle when
## ADVANCING and not aggroed.
@export var chase_speed: float = 5.0

# -------------------------
# Exports — Pressure state
# -------------------------

## Reference to the Castle actor.  Used for pressure-state distance checks
## and as the attack target when the group enters ATTACKING.
## Falls back to (0, 0) when unset.
@export var castle: Node2D

## Distance from the castle at which the group transitions ADVANCING → HOLDING.
@export var hold_distance: float = 300.0

## Distance from the castle at which HOLDING may transition to ATTACKING
## (once the hesitation timer has also expired).
@export var attack_distance: float = 150.0

## Extra distance buffer applied to the HOLDING → ADVANCING back-transition
## to prevent oscillation.
@export var hysteresis_margin: float = 40.0

## Minimum seconds the group hesitates in HOLDING before it may enter ATTACKING.
@export var hesitation_min: float = 1.0

## Maximum seconds the group hesitates in HOLDING before it may enter ATTACKING.
@export var hesitation_max: float = 3.0

# -------------------------
# Internal state
# -------------------------

## Frozen spawn position — set once by the spawner, never changes.
var spawn_pivot: Vector2 = Vector2.ZERO

## Slowly advances toward the castle each tick when ADVANCING and not aggroed.
## Initialized to spawn_pivot in _ready().
var target_position: Vector2 = Vector2.ZERO

var _members: Array[Enemy] = []
var _living_count: int = 0
var _was_depleted: bool = false

## Per-member anchor offsets relative to spawn_pivot / target_position.
## Stored when a member is registered so anchor_position updates automatically.
## When a formation is active these are derived from the slot grid; otherwise
## they are the raw scatter offsets passed in by the spawner.
var _anchor_offsets: Dictionary = { }

## Formation slot array — index = slot number, value = Enemy (null = empty).
## Only populated when formation_type != NONE.
var _slots: Array[Enemy] = []

## Accumulated time for position update (every POSITION_UPDATE_INTERVAL seconds).
var _position_timer: float = 0.0
const POSITION_UPDATE_INTERVAL := 0.1

## Cached player reference, resolved at _ready().
var _player: Node2D

# Dormant when player is too far away.
var _dormant_timer: float = 0.0
var dormant: bool = false

var _aggroed: bool = false
var _aggro_timer: float = 0.0

var _returning_to_spawn: bool = false

# How often to run the distance-based aggro check (seconds).
const AGGRO_CHECK_INTERVAL := 0.1

# -------------------------
# Pressure state internals
# -------------------------

var _pressure_state: PressureState = PressureState.ADVANCING

## Countdown in seconds before HOLDING may transition to ATTACKING.
## Starts at a random value in [hesitation_min, hesitation_max] on HOLDING entry.
var _hesitation_remaining: float = 0.0

var _rng := RandomNumberGenerator.new()

## Assigned by EncounterController via setup_slot() after the warning spawn lands.
## Used to track and enforce the per-direction advancing cap.
var slot_manager: DirectionalSlotManager = null
var dir_idx: int = -1
var _group_role: EnemyGroupProfile.GroupRole = EnemyGroupProfile.GroupRole.CLOSED

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    # Capture the node's world position as the pivot the moment it enters the tree.
    # The spawner should place the node at the desired center before add_child().
    spawn_pivot = global_position
    target_position = spawn_pivot

    _rng.randomize()

    _player = get_tree().get_first_node_in_group("player")

    if not detection_module:
        detection_module = find_child("DetectionModule", true, false) as DetectionModule

    if detection_module:
        detection_module.radius = deaggro_range


func _physics_process(delta: float) -> void:
    # Dormant check
    _dormant_timer += delta
    if _dormant_timer >= dormant_check_interval:
        _dormant_timer = 0.0
        _update_dormant_state()

    # Hesitation timer — only active in HOLDING state.
    if _pressure_state == PressureState.HOLDING:
        _hesitation_remaining -= delta

    # Update group position to the live centroid every POSITION_UPDATE_INTERVAL seconds.
    _position_timer += delta
    if _position_timer >= POSITION_UPDATE_INTERVAL:
        _position_timer = 0.0
        global_position = get_center()

        # Evaluate pressure state transitions each position tick.
        _update_pressure_state()

        # Propagate updated anchor_positions to all living members.
        for member in get_alive_members():
            var offset: Vector2 = _anchor_offsets.get(member, Vector2.ZERO)
            if _returning_to_spawn:
                member.anchor_position = spawn_pivot
            else:
                member.anchor_position = target_position + offset

        # Leash check runs after position update so global_position is current.
        _check_leash()

        if _returning_to_spawn:
            if global_position.distance_to(spawn_pivot) < (leash_distance / 4):
                _returning_to_spawn = false
    if dormant:
        return

    # Distance-based aggro check — replaces per-actor Area2D detection.
    _aggro_timer += delta
    if _aggro_timer >= AGGRO_CHECK_INTERVAL:
        _aggro_timer = 0.0
        _update_aggro_state()


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if _pressure_state == PressureState.ADVANCING:
            _leave_advancing()
        if not _was_depleted:
            group_removed.emit()

# -------------------------
# Member registry (called by SpawnEnemyGroupAction)
# -------------------------


func register_member(enemy: Enemy, setup_position: Vector2 = Vector2.ZERO) -> void:
    if _members.has(enemy):
        return

    if formation_type == FormationType.NONE:
        # Scatter mode — honour the raw spawn position provided by the spawner.
        if position == Vector2.ZERO:
            push_warning("EnemyGroup.register_member() called with null position")
        else:
            enemy.global_position = setup_position
            enemy.anchor_position = setup_position

        _anchor_offsets[enemy] = enemy.anchor_position - global_position
    else:
        # Formation mode — assign the next free slot and compute the grid offset.
        var slot_index := _get_first_empty_slot()
        # Grow the slot array if needed.
        while _slots.size() <= slot_index:
            _slots.append(null)
        _slots[slot_index] = enemy

        var offset := _convert_index_to_grid(slot_index) * grid_size
        _anchor_offsets[enemy] = offset

        enemy.global_position = spawn_pivot + offset
        enemy.anchor_position = spawn_pivot + offset

    _members.append(enemy)
    _living_count += 1

    if not enemy.died.is_connected(_on_member_died.bind(enemy)):
        enemy.died.connect(_on_member_died.bind(enemy))

    members_changed.emit()

# -------------------------
# Public API
# -------------------------


## Returns the live centroid of all members.
## Falls back to spawn_pivot when all members are dead (minimap icon stays in place).
func get_center() -> Vector2:
    var alive := get_alive_members()
    if alive.is_empty():
        return spawn_pivot

    var sum := Vector2.ZERO
    for m in alive:
        sum += m.global_position
    return sum / float(alive.size())


func get_alive_members() -> Array[Enemy]:
    var result: Array[Enemy] = []
    for m in _members:
        if is_instance_valid(m):
            result.append(m)
    return result


func get_member_count() -> int:
    return _living_count


func is_depleted() -> bool:
    return _living_count <= 0


## Immediately frees all living members and this group node.
## Does not emit group_depleted — use this for forced cleanup, not natural death.
func force_kill() -> void:
    for member in get_alive_members():
        member.queue_free()

    queue_free()


## Changes the active formation type and immediately re-assigns anchor offsets
## for all living members so the new layout takes effect at the next position tick.
func set_formation_type(type: FormationType) -> void:
    formation_type = type
    _rebuild_formation()


## Called by EncounterController after the group lands to register its slot manager,
## direction index, and role for advancing-cap enforcement.
## If the per-direction advancing cap is already full the group enters HOLDING
## immediately instead of continuing to advance.
func setup_slot(
    manager: DirectionalSlotManager,
    direction_idx: int,
    group_role: EnemyGroupProfile.GroupRole,
) -> void:
    slot_manager = manager
    dir_idx = direction_idx
    _group_role = group_role
    # The group starts ADVANCING by default — request permission.
    if _pressure_state == PressureState.ADVANCING:
        if not slot_manager.request_advancing(dir_idx, _group_role):
            _enter_holding()

# -------------------------
# Internal — formation
# -------------------------


func _rebuild_formation() -> void:
    var alive := get_alive_members()

    # Clear slot bookkeeping.
    _slots.clear()
    _anchor_offsets.clear()

    if formation_type == FormationType.NONE:
        # Restore scatter offsets: re-derive from current member positions.
        for member in alive:
            _anchor_offsets[member] = member.global_position - global_position
        return

    # Re-assign each living member a fresh formation slot.
    for i in range(alive.size()):
        var member := alive[i]
        while _slots.size() <= i:
            _slots.append(null)
        _slots[i] = member

        var offset := _convert_index_to_grid(i) * grid_size
        _anchor_offsets[member] = offset
        member.anchor_position = target_position + offset


func _get_first_empty_slot() -> int:
    for i in range(_slots.size()):
        if _slots[i] == null:
            return i
    return _slots.size()


## Dispatch to the correct formation-math function based on formation_type.
func _convert_index_to_grid(index: int) -> Vector2:
    match formation_type:
        FormationType.CIRCULAR:
            return _convert_index_to_circular(index)
        _:
            return _convert_index_to_rectangular(index)


## Rectangular (spiral) formation.
## Positions members in a square spiral expanding outward from the centre.
func _convert_index_to_rectangular(index: int) -> Vector2:
    index += 1
    if index <= 0:
        return Vector2.ZERO

    var k := int(ceil((sqrt(index + 1) - 1) / 2))
    var side_len := 2 * k
    var max_index := (2 * k + 1) * (2 * k + 1) - 1
    var offset := max_index - index

    if offset < side_len:
        return Vector2(k, -k + offset)
    offset -= side_len
    if offset < side_len:
        return Vector2(k - offset, k)
    offset -= side_len
    if offset < side_len:
        return Vector2(-k, k - offset)
    offset -= side_len
    return Vector2(-k + offset, -k)


## Circular (ring-based) formation.
## Ring 0: 1 slot; Ring k: 6·k slots; total through ring k = 1 + 3·k·(k+1).
func _convert_index_to_circular(index: int) -> Vector2:
    if index == 0:
        return Vector2.ZERO

    var k := int(floor((-3.0 + sqrt(9.0 + 12.0 * float(index - 1))) / 6.0)) + 1
    var ring_start := 1 + 3 * (k - 1) * k
    var pos_in_ring := index - ring_start
    var angle := pos_in_ring * TAU / float(6 * k)
    return Vector2(cos(angle) * k, sin(angle) * k)

# -------------------------
# Internal — pressure state machine
# -------------------------


## Evaluates transitions between ADVANCING, HOLDING, and ATTACKING.
## Called every POSITION_UPDATE_INTERVAL (0.1 s) from the position tick.
func _update_pressure_state() -> void:
    var castle_pos := _get_castle_pos()
    var dist := global_position.distance_to(castle_pos)

    match _pressure_state:
        PressureState.ADVANCING:
            if dist <= hold_distance:
                _leave_advancing()
                _enter_holding()

        PressureState.HOLDING:
            if dist > hold_distance + hysteresis_margin:
                _enter_advancing()
            elif dist <= attack_distance and _hesitation_remaining <= 0.0:
                _enter_attacking()

        PressureState.ATTACKING:
            pass  # Terminal — no outgoing transitions.


func _enter_advancing() -> void:
    if slot_manager != null and dir_idx >= 0:
        if not slot_manager.request_advancing(dir_idx, _group_role):
            # Cap hit — stay in or re-enter HOLDING.
            _enter_holding()
            return
    _pressure_state = PressureState.ADVANCING


func _enter_holding() -> void:
    _pressure_state = PressureState.HOLDING
    _hesitation_remaining = _rng.randf_range(hesitation_min, hesitation_max)


func _leave_advancing() -> void:
    if slot_manager == null or dir_idx < 0:
        return
    slot_manager.notify_left_advancing(dir_idx, _group_role)


func _enter_attacking() -> void:
    _pressure_state = PressureState.ATTACKING
    # Assign the castle as the group target so individual enemy FSMs can attack it.
    var castle_node := _get_castle_node()
    if castle_node != null:
        for member in get_alive_members():
            member.group_aggroed = true
            member.group_target = castle_node


func _get_castle_pos() -> Vector2:
    if is_instance_valid(castle):
        return castle.global_position
    return Vector2.ZERO


func _get_castle_node() -> Node2D:
    if is_instance_valid(castle):
        return castle
    return null

# -------------------------
# Internal
# -------------------------


func _update_aggro_state() -> void:
    if not _player:
        return

    if _returning_to_spawn:
        return

    var dist := _player.global_position.distance_to(global_position)

    if not _aggroed and dist < aggro_range:
        _aggroed = true
        _wake_all_members()
        _assign_targets_to_members()

    elif _aggroed:
        # Deaggro if no targets remain in detection range.
        if detection_module == null or detection_module.get_closest_target(false) == null:
            _aggroed = false
            _returning_to_spawn = true
            for member in get_alive_members():
                member.group_aggroed = false
                member.group_target = null
        else:
            # Re-assign each tick so members switch target if a closer one appears.
            _assign_targets_to_members()


func _assign_targets_to_members() -> void:
    var targets: Array[Node2D] = detection_module.get_targets(false) if detection_module else [_player]
    for member in get_alive_members():
        member.group_aggroed = true
        member.group_target = _get_closest_target_to(member.global_position, targets)


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


func _check_leash() -> void:
    if leash_distance <= 0.0:
        return

    # Use group center (global_position) as the leash reference — if the whole
    # group has drifted too far from spawn_pivot, pull everyone back at once.
    if global_position.distance_to(target_position) <= leash_distance:
        return

    _aggroed = false
    _returning_to_spawn = true
    _wake_all_members()
    for member in get_alive_members():
        # Reset each member's anchor to their original spawn slot so
        # RETURN_TO_ANCHOR navigates home, not the now-distant center.
        var offset: Vector2 = _anchor_offsets.get(member, Vector2.ZERO)
        member.anchor_position = target_position + offset
        member.group_aggroed = false
        member.group_target = null


func _on_member_died(_info, enemy: Enemy) -> void:
    var idx := _members.find(enemy)
    if idx != -1:
        _members.remove_at(idx)

    _anchor_offsets.erase(enemy)

    # Free the formation slot so it can be reused.
    var slot_idx := _slots.find(enemy)
    if slot_idx != -1:
        _slots[slot_idx] = null

    _living_count -= 1
    members_changed.emit()

    if _living_count <= 0:
        _was_depleted = true
        group_depleted.emit()
        queue_free()


func _update_dormant_state() -> void:
    if not _player:
        return

    if _returning_to_spawn:
        return

    if _aggroed:
        return

    # ADVANCING: creep target_position toward the castle.
    # HOLDING / ATTACKING: target_position is frozen at the group level.
    if _pressure_state == PressureState.ADVANCING:
        var castle_pos := _get_castle_pos()
        target_position = target_position.move_toward(
            castle_pos,
            chase_speed * dormant_check_interval,
        )

    var dist := _player.global_position.distance_to(global_position)
    var should_sleep := dist > dormant_distance

    if should_sleep == dormant:
        return

    dormant = should_sleep
    for member in get_alive_members():
        member.dormant = should_sleep
        member.set_enabled(not should_sleep)


func _wake_all_members() -> void:
    if not dormant:
        return
    dormant = false
    for member in get_alive_members():
        member.dormant = false
        member.set_enabled(true)
