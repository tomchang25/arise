extends EnemyState

var animation_state: String = Enemy.AnimationState.MOVE


func _init() -> void:
    state_id = EnemyStateId.WANDER


func _enter() -> void:
    enemy.play_animation(animation_state)


func _update(_delta: float) -> void:
    enemy.move_to_position(enemy.next_position, enemy.wander_speed, 5.0)

    var movement_vector = enemy.get_velocity()
    enemy.set_facing_direction(movement_vector, animation_state)

    if enemy.is_navigation_finished():
        change_state(EnemyStateId.IDLE)
        return

    if enemy.is_target_tracked():
        change_state(EnemyStateId.CHASE)
        return
