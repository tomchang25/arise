## Fires a ranged (projectile) attack toward the player when in reach and weapon is ready.
## The enemy stands still while this action is RUNNING.
## Returns FAILURE when the player moves out of reach.
class_name RangedAttackAction
extends ActionLeaf

@export var weapon_index: int = 0
@export var attack_index: int = 0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy := actor as Enemy
	if enemy == null:
		return FAILURE

	if not enemy.is_player_in_reach():
		return FAILURE

	var target := enemy.get_nearest_reachable_target()
	if target == null:
		return FAILURE

	enemy.stop_movement()
	enemy.set_facing_direction(
		enemy.global_position.direction_to(target.global_position),
		Enemy.ANIM_ATTACK
	)

	# Auto-end immediately after firing to start the cooldown timer.
	if enemy.can_attack(weapon_index, attack_index):
		enemy.play_animation(Enemy.ANIM_ATTACK)
		enemy.perform_attack(target.global_position, weapon_index, attack_index)
		enemy.end_attack(weapon_index, attack_index)

	return RUNNING
