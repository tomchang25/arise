extends EnemyState

@export var animation_state: String = "Idle"

@export var min_wait_time: float = 3.0
@export var max_wait_time: float = 10.0


func _init() -> void:
    state_id = EnemyStateId.IDLE


func _enter() -> void:
    enemy.movement.stop()

    enemy.animation.travel_to_state(animation_state)

    _setup_wait_timer()


func _update(_delta: float) -> void:
    if enemy.enemy_scanner.is_enemy_tracked():
        change_state(EnemyStateId.CHASE)
        return


func _exit() -> void:
    pass


func _setup_wait_timer() -> void:
    enemy.wait_timer.wait_time = randf_range(min_wait_time, max_wait_time)
    enemy.wait_timer.start()


func _on_wait_timer_timeout() -> void:
    change_state(EnemyStateId.WANDER)
    return
