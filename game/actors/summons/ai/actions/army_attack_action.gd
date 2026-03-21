## Attacks the nearest enemy within reach.
## Returns RUNNING while the target remains attackable.
## Returns FAILURE when the target moves out of reach or the unit drifts too
## far from the player — the SelectorReactive will then re-evaluate the tree
## and fall back to the Chase or Follow branch as appropriate.
class_name ArmyAttackAction
extends ActionLeaf

@export var weapon_index: int = 0
@export var attack_index: int = 0
## Maximum distance from the player before the unit abandons the attack.
@export var follow_threshold: float = 250.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var army := actor as Army
	if army == null:
		return FAILURE

	if army.get_distance_to_player() > follow_threshold:
		army.stop_movement()
		return FAILURE

	var target := army.get_nearest_attackable_target()
	if target == null:
		return FAILURE

	army.stop_movement()
	army.set_facing_direction(
		army.global_position.direction_to(target.global_position),
		Army.ANIM_ATTACK,
	)

	if army.can_attack(weapon_index, attack_index):
		army.play_animation(Army.ANIM_ATTACK, 1.0, true)
		army.perform_attack(target.global_position, weapon_index, attack_index)
		army.end_attack(weapon_index, attack_index)

	return RUNNING
