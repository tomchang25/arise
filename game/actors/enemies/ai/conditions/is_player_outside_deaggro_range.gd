## Returns SUCCESS if the player has moved outside the deaggro zone.
## Returns FAILURE if the player is still within deaggro range.
class_name IsPlayerOutsideDeaggroRange
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE
    return SUCCESS if enemy.is_player_outside_deaggro_range() else FAILURE
