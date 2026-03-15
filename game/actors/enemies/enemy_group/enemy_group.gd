class_name EnemyGroup
extends Node2D

## Emitted when the last living member dies.
signal group_depleted

## Emitted whenever the member list changes (for minimap or UI).
signal members_changed

# -------------------------
# Internal state
# -------------------------

## Frozen spawn position — set once by the spawner, never changes.
var spawn_pivot: Vector2 = Vector2.ZERO

var _members: Array[Enemy] = []

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    # Capture the node's world position as the pivot the moment it enters the tree.
    # The spawner should place the node at the desired center before add_child().
    spawn_pivot = global_position


# -------------------------
# Member registry (called by spawner)
# -------------------------


func register_member(enemy: Enemy) -> void:
    if _members.has(enemy):
        return

    _members.append(enemy)

    # Listen for death so we can deregister and check depletion
    if enemy.damage_receiver and not enemy.damage_receiver.died.is_connected(_on_member_died.bind(enemy)):
        enemy.damage_receiver.died.connect(_on_member_died.bind(enemy))

    members_changed.emit()


func unregister_member(enemy: Enemy) -> void:
    var idx := _members.find(enemy)
    if idx == -1:
        return

    _members.remove_at(idx)
    members_changed.emit()
    _check_depleted()


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
    return get_alive_members().size()


func is_depleted() -> bool:
    return get_alive_members().is_empty()


# -------------------------
# Internal
# -------------------------


func _on_member_died(_info: AttackData, enemy: Enemy) -> void:
    unregister_member(enemy)


func _check_depleted() -> void:
    if is_depleted():
        group_depleted.emit()
        queue_free()
