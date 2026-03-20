class_name IsHomeTooFar
extends ConditionLeaf

@export var max_distance: float = 200.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var dist = actor.global_position.distance_to(actor.home_position)

    if dist > max_distance:
        return SUCCESS

    return FAILURE
