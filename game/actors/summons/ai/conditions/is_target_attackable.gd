## Returns SUCCESS if the actor has at least one target within attack reach.
## Returns FAILURE otherwise.
class_name ArmyIsTargetAttackable
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var a := actor as Actor
    if a == null:
        return FAILURE
    return SUCCESS if a.is_target_in_reach() else FAILURE
