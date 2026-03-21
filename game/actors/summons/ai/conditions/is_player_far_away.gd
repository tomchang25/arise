## Returns SUCCESS if the army unit is farther than [threshold] units from its
## formation slot (player position + grid_position). Used to trigger the Follow
## branch in the behaviour tree.
class_name ArmyIsPlayerFarAway
extends ConditionLeaf

@export var threshold: float = 16.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null:
        return FAILURE
    return SUCCESS if army.get_distance_to_player() > threshold else FAILURE
