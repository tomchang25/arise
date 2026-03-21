## Enemy-specific state base. Extends ActorState and exposes a typed
## Enemy reference for convenience in Enemy-only states.
class_name EnemyState
extends ActorState

## Re-export Enemy state IDs for backward compatibility with existing enemy state scripts.
enum EnemyStateId {
    NULL = ActorStateId.NULL,
    IDLE = ActorStateId.IDLE,
    WANDER = ActorStateId.WANDER,
    CHASE = ActorStateId.CHASE,
    ATTACK = ActorStateId.ATTACK,
    BACK = ActorStateId.RETURN_TO_ANCHOR,
    LEASH_BACK = ActorStateId.LEASH_BACK,
    CHARGE_WINDUP = ActorStateId.CHARGE_WINDUP,
    CHARGE = ActorStateId.CHARGE,
    CHARGE_RECOVERY = ActorStateId.CHARGE_RECOVERY,
}

## Typed shortcut — use actor (from ActorState) for the common Actor API.
var enemy: Enemy


func _ready() -> void:
    await owner.ready
    actor = owner as Actor
    enemy = owner as Enemy
