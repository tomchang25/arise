extends EnemyState


func _init() -> void:
    state_id = EnemyStateId.IDLE


func _enter() -> void:
    enemy.stop_movement()
    enemy.play_animation(Enemy.AnimationState.IDLE)
    

func _update(_delta: float) -> void:
    if enemy.is_target_tracked():
        change_state(EnemyStateId.CHASE)
        return

    if enemy.next_position.distance_to(enemy.global_position) > 10:
        change_state(EnemyStateId.WANDER)
        return
