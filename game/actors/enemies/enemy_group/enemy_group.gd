class_name EnemyGroup
extends Node2D

## Emitted when every member died via their died signal — player cleared the group.
signal group_depleted

## Emitted when the group is removed for any other reason — despawn, queue_free, etc.
signal group_removed

## Emitted whenever the member list changes (for minimap or UI).
signal members_changed

# -------------------------
# Internal state
# -------------------------

## Frozen spawn position — set once by the spawner, never changes.
var spawn_pivot: Vector2 = Vector2.ZERO

var _members: Array[Enemy] = []
var _living_count: int = 0
var _was_depleted: bool = false

## Per-member anchor offsets relative to this group node's position.
## Stored when a member is registered so anchor_position updates automatically
## whenever the group node moves.
var _anchor_offsets: Dictionary = {}

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    # Capture the node's world position as the pivot the moment it enters the tree.
    # The spawner should place the node at the desired center before add_child().
    spawn_pivot = global_position


func _physics_process(_delta: float) -> void:
    # Propagate updated anchor_positions whenever this group node moves.
    for member in get_alive_members():
        var offset: Vector2 = _anchor_offsets.get(member, Vector2.ZERO)
        member.anchor_position = global_position + offset


func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        if not _was_depleted:
            group_removed.emit()


# -------------------------
# Member registry (called by SpawnEnemyGroupAction)
# -------------------------


func register_member(enemy: Enemy) -> void:
    if _members.has(enemy):
        return

    _members.append(enemy)
    _living_count += 1

    # Store the member's anchor offset relative to this group's current position.
    # SpawnEnemyGroupAction sets enemy.anchor_position before calling register_member(),
    # so we capture it here as the authoritative offset.
    _anchor_offsets[enemy] = enemy.anchor_position - global_position

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


# -------------------------
# Internal
# -------------------------


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
