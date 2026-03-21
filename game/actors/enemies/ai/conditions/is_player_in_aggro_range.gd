## Returns SUCCESS if the actor has targets in its aggro detection range.
## Returns FAILURE otherwise.
class_name IsPlayerInAggroRange
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var a := actor as Actor
    if a == null:
        return FAILURE
    return SUCCESS if a.is_aggro_active() else FAILURE
