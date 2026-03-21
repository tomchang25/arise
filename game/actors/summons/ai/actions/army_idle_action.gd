## Stops the unit and plays the idle animation.
## Returns RUNNING indefinitely — the SelectorReactive re-evaluates priority
## branches each tick, so a higher-priority branch will preempt idle as soon
## as its condition becomes true.
class_name ArmyIdleAction
extends ActionLeaf

func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null:
        return FAILURE
    army.stop_movement()
    army.play_animation(Army.ANIM_IDLE)
    return RUNNING
