## Unified state base class for all actor state machines (Army and Enemy).
## Replaces the separate ArmyState and EnemyState bases.
class_name ActorState
extends State

enum ActorStateId {
	NULL = -1,
	IDLE = 0,
	RETURN_TO_ANCHOR = 1,  ## Go back to anchor_position (replaces FOLLOW/BACK/LEASH_BACK)
	CHASE = 2,
	ATTACK = 3,
	WANDER = 4,            ## Enemy-specific: wander near anchor when idle
	LEASH_BACK = 5,        ## Enemy elite: forced return when leash exceeded
	CHARGE_WINDUP = 6,     ## Enemy elite: telegraph before charge
	CHARGE = 7,            ## Enemy elite: dash attack
	CHARGE_RECOVERY = 8,   ## Enemy elite: stunned after charge
}

## Typed reference to the owning actor. Set automatically in _ready().
var actor: Actor


func _ready() -> void:
	await owner.ready
	actor = owner as Actor
