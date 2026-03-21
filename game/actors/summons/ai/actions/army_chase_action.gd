## Chases the nearest tracked enemy target.
## Returns RUNNING while chasing.
## Returns FAILURE if the target is lost or the unit drifts too far from the player.
class_name ArmyChaseAction
extends ActionLeaf

@export var chase_speed: float = 50.0
## Maximum distance from the player before the unit abandons the chase.
@export var follow_threshold: float = 250.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null:
        return FAILURE

    if army.get_distance_to_anchor() > follow_threshold:
        army.stop_movement()
        return FAILURE

    var target := army.get_nearest_aggro_target()
    if target == null:
        army.stop_movement()
        return FAILURE

    if target.global_position.distance_to(army.global_position) > follow_threshold:
        army.stop_movement()
        return FAILURE

    if target.global_position.distance_to(army.player.global_position) > follow_threshold:
        army.stop_movement()
        return FAILURE

    var arrive_dist := army.data.attack_range / 2.0 if army.data else 25.0
    army.move_to_position(target.global_position, chase_speed, arrive_dist)
    army.set_facing_direction(
        army.global_position.direction_to(target.global_position),
        Army.ANIM_MOVE,
    )
    army.play_animation(Army.ANIM_MOVE)
    return RUNNING
