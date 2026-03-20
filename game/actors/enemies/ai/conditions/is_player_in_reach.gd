## Returns SUCCESS if the player is within attack reach distance.
## Returns FAILURE otherwise.
class_name IsPlayerInReach
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE
    return SUCCESS if enemy.is_player_in_reach() else FAILURE
