## Returns SUCCESS if the army unit has at least one aggro target.
## Returns FAILURE otherwise.
class_name ArmyIsTargetTracked
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null:
        return FAILURE
    return SUCCESS if army.is_aggro_active() else FAILURE
