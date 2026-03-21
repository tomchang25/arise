## Army-specific state base. Extends ActorState and exposes a typed
## Army reference for convenience in Army-only states.
class_name ArmyState
extends ActorState

## Re-export Army state IDs for backward compatibility with existing army state scripts.
enum ArmyStateId {
    NULL = -1,
    IDLE = ActorStateId.IDLE,
    FOLLOW = ActorStateId.RETURN_TO_ANCHOR,
    CHASE = ActorStateId.CHASE,
    RETREAT = ActorStateId.RETURN_TO_ANCHOR,
    ATTACK = ActorStateId.ATTACK,
}

## Typed shortcut — use actor (from ActorState) for the common Actor API.
var target: Army


func _ready() -> void:
    if owner == null:
        push_error("ArmyState must have an owner")
        return

    if not owner.is_node_ready():
        await owner.ready

    if owner is not Army:
        push_error("ArmyState owner must be an Army")
        return

    actor = owner
    target = owner
