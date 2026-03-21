## Returns SUCCESS if the actor is farther than [threshold] units from its
## formation slot (anchor_position). Used to trigger the Follow branch in the
## behaviour tree.
class_name ArmyIsPlayerFarAway
extends ConditionLeaf

@export var threshold: float = 16.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var a := actor as Actor
    if a == null:
        return FAILURE
    return SUCCESS if a.get_distance_to_anchor() > threshold else FAILURE
