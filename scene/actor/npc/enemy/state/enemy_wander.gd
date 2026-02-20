extends EnemyState

var animation_state: String = Enemy.AnimationState.MOVE

var target_position: Vector2


func _init() -> void:
    state_id = EnemyStateId.WANDER


func _enter() -> void:
    var random_direction = Vector2.RIGHT.rotated(randf() * TAU)
    var random_distance = randf() * enemy.wander_range
    target_position = enemy.home_position + (random_direction * random_distance)

    enemy.play_animation(animation_state)

    if not enemy.navigation_finished.is_connected(_on_navigation_finished):
        enemy.navigation_finished.connect(_on_navigation_finished)


func _exit() -> void:
    if enemy.navigation_finished.is_connected(_on_navigation_finished):
        enemy.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
    enemy.move_to_position(target_position, enemy.wander_speed, 5.0)

    var movement_vector = enemy.get_velocity()
    if movement_vector.length() > 0.1:
        enemy.set_facing_direction(movement_vector, animation_state)

    if enemy.is_target_tracked():
        change_state(EnemyStateId.CHASE)
        return


func _on_navigation_finished() -> void:
    change_state(EnemyStateId.IDLE)
    return
