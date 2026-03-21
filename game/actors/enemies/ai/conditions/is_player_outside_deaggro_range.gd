## Returns SUCCESS if the actor's target has moved outside the deaggro zone.
## Returns FAILURE if the target is still within deaggro range.
class_name IsPlayerOutsideDeaggroRange
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var a := actor as Actor
    if a == null:
        return FAILURE
    return SUCCESS if a.is_deaggro_active() else FAILURE
