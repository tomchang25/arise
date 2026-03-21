## Moves the army unit toward its formation slot (player position + grid_position).
## Returns RUNNING while travelling.
## Returns FAILURE if the player reference is missing.
class_name ArmyFollowAction
extends ActionLeaf

@export var move_speed: float = 100.0
@export var arrive_distance: float = 5.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null or army.player == null:
        return FAILURE

    army.move_to_position(
        army.player.global_position + army.grid_position,
        move_speed,
        arrive_distance,
    )

    var velocity := army.get_path_velocity()
    army.set_facing_direction(velocity, Army.ANIM_MOVE)
    army.play_animation(Army.ANIM_MOVE)
    return RUNNING
