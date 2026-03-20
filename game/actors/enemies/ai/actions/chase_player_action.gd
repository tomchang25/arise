## Chases the nearest detected player.
## Returns RUNNING while chasing.
## Returns FAILURE if no aggro target is found (e.g. player left detection range).
class_name ChasePlayerAction
extends ActionLeaf

@export var chase_speed: float = 150.0
## Leash distance from home_position before the enemy gives up chasing.
@export var leash_distance: float = 300.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy := actor as Enemy
	if enemy == null:
		return FAILURE

	# Leash check — stop chasing if too far from home.
	if enemy.get_distance_to_home() > leash_distance:
		enemy.stop_movement()
		return FAILURE

	var target := enemy.get_nearest_aggro_target()
	if target == null:
		enemy.stop_movement()
		return FAILURE

	var stop_dist := 0.0
	if enemy.reach_detection:
		stop_dist = enemy.reach_detection.radius * 0.5

	enemy.move_to_position(target.global_position, chase_speed, stop_dist)
	enemy.set_facing_direction(
		enemy.global_position.direction_to(target.global_position),
		Enemy.ANIM_MOVE
	)
	enemy.play_animation(Enemy.ANIM_MOVE, 1.5)
	return RUNNING
