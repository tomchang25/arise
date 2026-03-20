## Moves the enemy back to its home_position.
## Returns SUCCESS when the enemy reaches home.
## Returns RUNNING while travelling.
class_name ReturnHomeAction
extends ActionLeaf

@export var back_speed: float = 80.0
@export var arrive_distance: float = 8.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy := actor as Enemy
	if enemy == null:
		return FAILURE

	if enemy.get_distance_to_home() <= arrive_distance:
		enemy.stop_movement()
		return SUCCESS

	enemy.move_to_position(enemy.home_position, back_speed, arrive_distance)
	enemy.set_facing_direction(
		enemy.global_position.direction_to(enemy.home_position),
		Enemy.ANIM_MOVE
	)
	enemy.play_animation(Enemy.ANIM_MOVE)
	return RUNNING
