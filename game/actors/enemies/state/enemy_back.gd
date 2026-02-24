extends EnemyState

@export var animation_state: String = Enemy.AnimationState.MOVE


func _init() -> void:
    state_id = EnemyStateId.BACK


func _enter() -> void:
    enemy.play_animation(animation_state)
    enemy.move_to_position(enemy.home_position, enemy.back_speed, 5.0)

    enemy.navigation_finished.connect(_on_navigation_finished)


func _exit() -> void:
    if enemy.navigation_finished.is_connected(_on_navigation_finished):
        enemy.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
    # Update movement and direction via the Enemy API
    enemy.move_to_position(enemy.home_position, enemy.back_speed, 5.0)

    var current_velocity = enemy.get_velocity()
    enemy.set_facing_direction(current_velocity, animation_state)

    # Transition: Return to Idle once the start position is reached
    # if enemy.is_navigation_finished():
    #     change_state(EnemyStateId.IDLE)
    #     return

    # Optional: Re-engage if player is tracked (commented out in source) [cite: 25]
    # if enemy.is_target_tracked():
    #     change_state(EnemyStateId.CHASE)
    #     return


func _on_navigation_finished() -> void:
    change_state(EnemyStateId.IDLE)
