extends EnemyState

@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0

var idle_timer: float = 0.0
var current_wait_time: float = 0.0


func _init() -> void:
    state_id = EnemyStateId.IDLE


func _enter() -> void:
    enemy.stop_movement()
    enemy.play_animation(Enemy.AnimationState.IDLE)

    current_wait_time = randf_range(min_idle_time, max_idle_time)
    idle_timer = 0.0


func _update(delta: float) -> void:
    if enemy.is_target_tracked():
        change_state(EnemyStateId.CHASE)
        return

    idle_timer += delta
    if idle_timer >= current_wait_time:
        change_state(EnemyStateId.WANDER)
        return
    # if enemy.next_position.distance_to(enemy.global_position) > 10:
    #     change_state(EnemyStateId.WANDER)
    #     return
