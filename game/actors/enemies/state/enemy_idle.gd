extends EnemyState

@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0

var _idle_timer: float = 0.0
var _wait_time: float = 0.0


func _init() -> void:
	state_id = EnemyStateId.IDLE


func _enter() -> void:
	enemy.stop_movement()
	enemy.play_animation(Actor.ANIM_IDLE)

	_wait_time = randf_range(min_idle_time, max_idle_time)
	_idle_timer = 0.0


func _update(delta: float) -> void:
	if enemy.is_player_in_aggro_range():
		change_state(EnemyStateId.CHASE)
		return

	_idle_timer += delta
	if _idle_timer >= _wait_time:
		change_state(EnemyStateId.WANDER)
