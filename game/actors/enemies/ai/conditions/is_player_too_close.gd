## Returns SUCCESS if the player is closer than reach_threshold * reach_radius.
## Used by the Skull enemy to trigger retreat behaviour.
class_name IsPlayerTooClose
extends ConditionLeaf

## Fraction of reach radius considered "too close". Default matches Skull spec (0.5).
@export var threshold: float = 0.5


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE
    if enemy.reach_detection == null:
        return FAILURE
    var target := enemy.get_nearest_aggro_target()
    if target == null:
        return FAILURE
    var dist := enemy.global_position.distance_to(target.global_position)
    var limit := enemy.reach_detection.radius * threshold
    return SUCCESS if dist < limit else FAILURE
