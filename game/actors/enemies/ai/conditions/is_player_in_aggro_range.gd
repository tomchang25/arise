## Returns SUCCESS if the player is inside the enemy's aggro detection range
## (with line-of-sight check). Returns FAILURE otherwise.
class_name IsPlayerInAggroRange
extends ConditionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE
    return SUCCESS if enemy.is_player_in_aggro_range() else FAILURE
