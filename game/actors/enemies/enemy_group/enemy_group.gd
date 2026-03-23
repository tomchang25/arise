class_name EnemyGroup
extends Node2D

## Emitted when every member died via their died signal — player cleared the group.
signal group_depleted

## Emitted when the group is removed for any other reason — despawn, queue_free, etc.
signal group_removed

## Emitted whenever the member list changes (for minimap or UI).
signal members_changed

# -------------------------
# Exports — Anchor tracking
# -------------------------

## When enabled, the anchor is updated to the player's world position every
## [member track_interval] seconds instead of being fixed in place.
@export var track_player: bool = false

## Seconds between automatic anchor updates when [member track_player] is true.
@export var track_interval: float = 5.0

@export var dormant_distance: float = 480.0
@export var dormant_check_interval: float = 1.0

## Distance from group center at which members aggro the player.
@export var aggro_range: float = 240.0

## Distance from group center at which members deaggro.
## Should be larger than aggro_range to prevent oscillation.
@export var deaggro_range: float = 320.0

# -------------------------
# Internal state
# -------------------------

## Frozen spawn position — set once by the spawner, never changes.
var spawn_pivot: Vector2 = Vector2.ZERO

var _members: Array[Enemy] = []
var _living_count: int = 0
var _was_depleted: bool = false

## The logical anchor position used to compute each member's formation slot.
## Stored as a plain Vector2 so that changing it does NOT move children.
var _anchor: Vector2 = Vector2.ZERO

## Per-member anchor offsets relative to _anchor.
## Stored when a member is registered so anchor_position updates automatically
## whenever set_anchor() is called.
var _anchor_offsets: Dictionary = { }

## Accumulated time for [member track_player] periodic updates.
var _track_timer: float = 0.0

## Cached player reference, resolved at _ready().
var _player: Node2D

# Dormant when player is too far away.
var _dormant_timer: float = 0.0
var dormant: bool = false

var _aggroed: bool = false
var _aggro_timer: float = 0.0

# How often to run the distance-based aggro check (seconds).
const AGGRO_CHECK_INTERVAL := 0.1

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    # Capture the node's world position as the pivot the moment it enters the tree.
    # The spawner should place the node at the desired center before add_child().
    spawn_pivot = global_position
    _anchor = global_position

    _player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
    # Optionally update the anchor to the player's position every N seconds.
    if track_player and _player:
        _track_timer += delta
        if _track_timer >= track_interval:
            _track_timer = 0.0
            set_anchor(_player.global_position)

    # Dormant check
    _dormant_timer += delta
    if _dormant_timer >= dormant_check_interval:
        _dormant_timer = 0.0
        _update_dormant_state()

    if dormant:
        return

    # Distance-based aggro check — replaces per-actor Area2D detection.
    _aggro_timer += delta
    if _aggro_timer >= AGGRO_CHECK_INTERVAL:
        _aggro_timer = 0.0
        _update_aggro_state()

    # Propagate updated anchor_positions to all living members.
    for member in get_alive_members():
        var offset: Vector2 = _anchor_offsets.get(member, Vector2.ZERO)
        member.anchor_position = _anchor + offset


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if not _was_depleted:
            group_removed.emit()

# -------------------------
# Member registry (called by SpawnEnemyGroupAction)
# -------------------------


func register_member(enemy: Enemy, setup_position: Vector2 = Vector2.ZERO) -> void:
    if _members.has(enemy):
        return

    if position == Vector2.ZERO:
        push_warning("EnemyGroup.register_member() called with null position")
    else:
        enemy.global_position = setup_position
        enemy.anchor_position = setup_position

    _members.append(enemy)
    _living_count += 1

    # Store the member's anchor offset relative to the current _anchor.
    # SpawnEnemyGroupAction sets enemy.anchor_position before calling register_member(),
    # so we capture it here as the authoritative offset.
    _anchor_offsets[enemy] = enemy.anchor_position - _anchor

    if not enemy.died.is_connected(_on_member_died.bind(enemy)):
        enemy.died.connect(_on_member_died.bind(enemy))

    members_changed.emit()

# -------------------------
# Public API
# -------------------------


## Moves the formation anchor to [param new_position] and immediately updates
## every member's anchor_position. Does NOT move the Node2D itself.
func set_anchor(new_position: Vector2) -> void:
    _anchor = new_position
    for member in get_alive_members():
        var offset: Vector2 = _anchor_offsets.get(member, Vector2.ZERO)
        member.anchor_position = _anchor + offset


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

# -------------------------
# Internal
# -------------------------


func _update_aggro_state() -> void:
    if not _player:
        return

    var dist := _player.global_position.distance_to(get_center())

    if not _aggroed and dist < aggro_range:
        _aggroed = true
        for member in get_alive_members():
            member.group_aggroed = true
            member.group_target = _player
            member.state_machine.request_transition(ActorState.ActorStateId.CHASE)

    elif _aggroed and dist > deaggro_range:
        _aggroed = false
        for member in get_alive_members():
            member.group_aggroed = false
            member.group_target = null
            member.state_machine.request_transition(ActorState.ActorStateId.RETURN_TO_ANCHOR)


func _on_member_died(_info, enemy: Enemy) -> void:
    var idx := _members.find(enemy)
    if idx != -1:
        _members.remove_at(idx)

    _anchor_offsets.erase(enemy)
    _living_count -= 1
    members_changed.emit()

    if _living_count <= 0:
        _was_depleted = true
        group_depleted.emit()
        queue_free()


func _update_dormant_state() -> void:
    if not _player:
        return

    var dist := _player.global_position.distance_to(_anchor)
    var should_sleep := dist > dormant_distance

    if should_sleep == dormant:
        return

    dormant = should_sleep
    for member in get_alive_members():
        member.dormant = should_sleep
        member.set_enabled(not should_sleep)
