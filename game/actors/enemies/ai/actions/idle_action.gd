## Plays the idle animation and stops movement.
## Returns RUNNING while the enemy has no aggro target.
## Returns FAILURE as soon as a target is detected (allows the selector to
## pick the next branch on the following tick).
class_name IdleAction
extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE
    enemy.stop_movement()
    enemy.play_animation(Enemy.ANIM_IDLE)
    return RUNNING
