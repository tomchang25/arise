## Attacks the nearest enemy within reach.
## Keeps the unit slowly repositioning toward the target while in attack range.
## Returns RUNNING while the target remains attackable.
## Returns FAILURE when the target moves out of reach — the SelectorReactive
## will then re-evaluate the tree and fall back to the Chase or Follow branch.
class_name ArmyAttackAction
extends ActionLeaf

@export var weapon_index: int = 0
@export var attack_index: int = 0
## Slow creep speed while repositioning during the attack.
@export var attack_speed: float = 50.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var army := actor as Army
    if army == null:
        return FAILURE

    var target := army.get_nearest_reachable_target()
    if target == null:
        return FAILURE

    # Slow creep: nudge toward the target when they're in the outer band,
    # stop when close enough.
    var reach := _get_reach_radius(army)
    if reach > 0.0:
        var dist := army.global_position.distance_to(target.global_position)
        var close_threshold := reach * 0.25
        var creep_threshold := reach * 0.75
        if dist > creep_threshold:
            army.move_to_position(target.global_position, attack_speed, close_threshold)
            army.set_facing_direction(
                army.global_position.direction_to(target.global_position),
                Army.ANIM_ATTACK,
            )
        elif dist <= close_threshold:
            army.stop_movement()

    # Fire when ready. Auto-end immediately to start the cooldown timer.
    if army.can_attack(weapon_index, attack_index):
        army.play_animation(Army.ANIM_ATTACK, 1.0, true)
        army.perform_attack(target.global_position, weapon_index, attack_index)
        army.end_attack(weapon_index, attack_index)
        army.set_facing_direction(
            army.global_position.direction_to(target.global_position),
            Army.ANIM_ATTACK,
        )

    return RUNNING


func _get_reach_radius(army: Army) -> float:
    if army.reach_detection:
        return army.reach_detection.radius
    return 0.0
