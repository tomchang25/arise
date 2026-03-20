## Periodically updates the enemy's home_position to the nearest detected player's position.
## This forces re-engagement by anchoring the leash at the player every [interval] seconds.
## Always returns SUCCESS so it never blocks the behaviour tree.
class_name UpdateHomePositionAction
extends ActionLeaf

## How often (seconds) to snap home_position to the player's position.
@export var interval: float = 10.0

var _last_update_ms: int = 0


func before_run(_actor: Node, _blackboard: Blackboard) -> void:
	_last_update_ms = Time.get_ticks_msec()


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var enemy := actor as Enemy
	if enemy == null:
		return SUCCESS

	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_update_ms >= int(interval * 1000.0):
		_last_update_ms = now_ms
		# Prefer an aggro target; fall back to any target in deaggro range.
		var target: Node2D = enemy.get_nearest_aggro_target()
		if target == null and enemy.deaggro_detection:
			target = enemy.deaggro_detection.get_closest_target(false)
		if target:
			enemy.home_position = target.global_position

	return SUCCESS
