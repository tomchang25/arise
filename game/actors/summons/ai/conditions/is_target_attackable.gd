## Returns SUCCESS if the army unit has at least one target within attack reach.
## Returns FAILURE otherwise.
class_name ArmyIsTargetAttackable
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null:
        return FAILURE
    return SUCCESS if army.is_target_attackable() else FAILURE
