## Moves the enemy away from the player until a safe distance is reached.
## Used by the Skull to retreat when the player gets too close.
## Returns RUNNING while retreating.
## Returns SUCCESS when the enemy has backed off to [retreat_until_fraction] * reach_radius.
class_name RetreatAction
extends ActionLeaf

## Start retreating when closer than this fraction of reach radius.
@export var trigger_fraction: float = 0.5
## Stop retreating once this fraction of reach radius is achieved.
@export var stop_fraction: float = 0.9
@export var retreat_speed: float = 120.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy := actor as Enemy
	if enemy == null:
		return FAILURE

	if enemy.reach_detection == null:
		return FAILURE

	var target := enemy.get_nearest_aggro_target()
	if target == null:
		return SUCCESS

	var dist := enemy.global_position.distance_to(target.global_position)
	var reach := enemy.reach_detection.radius
	var stop_dist := reach * stop_fraction

	if dist >= stop_dist:
		enemy.stop_movement()
		return SUCCESS

	# Move away from the player.
	var away_dir := enemy.global_position.direction_to(target.global_position) * -1.0
	var retreat_target := enemy.global_position + away_dir * retreat_speed
	enemy.move_to_position(retreat_target, retreat_speed, 4.0)
	enemy.set_facing_direction(
		enemy.global_position.direction_to(target.global_position),
		Enemy.ANIM_MOVE
	)
	enemy.play_animation(Enemy.ANIM_MOVE)
	return RUNNING
