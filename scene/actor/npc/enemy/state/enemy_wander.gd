extends EnemyState

var animation_state: String = Enemy.AnimationState.MOVE


func _init() -> void:
    state_id = EnemyStateId.WANDER


func _enter() -> void:
    enemy.play_animation(animation_state)

    enemy.navigation_finished.connect(_on_navigation_finished)


func _exit() -> void:
    if enemy.navigation_finished.is_connected(_on_navigation_finished):
        enemy.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
    enemy.move_to_position(enemy.next_position, enemy.wander_speed, 5.0)

    var movement_vector = enemy.get_velocity()
    enemy.set_facing_direction(movement_vector, animation_state)

    if enemy.is_target_tracked():
        change_state(EnemyStateId.CHASE)
        return


func _on_navigation_finished() -> void:
    change_state(EnemyStateId.IDLE)
