## Returns SUCCESS if the actor is within attack reach distance.
## Returns FAILURE otherwise.
class_name IsPlayerInReach
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var a := actor as Actor
    if a == null:
        return FAILURE
    return SUCCESS if a.is_target_in_reach() else FAILURE
