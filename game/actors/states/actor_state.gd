## Unified state base class for all actor state machines (Army and Enemy).
## Replaces the separate ArmyState and EnemyState bases.
class_name ActorState
extends State

enum ActorStateId {
    NULL = -1,
    IDLE = 0,
    RETURN_TO_ANCHOR = 1,
    CHASE = 2,
    ATTACK = 3,
    WANDER = 4,
}

## Typed reference to the owning actor. Set automatically in _ready().
var actor: Actor


func _ready() -> void:
    await owner.ready
    actor = owner as Actor
