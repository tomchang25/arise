extends EnemyState

@export var animation_state: String = "Move"
@export var wander_speed: float = 50


func _init() -> void:
    state_id = EnemyStateId.WANDER


func _enter() -> void:
    enemy.generate_random_wander_position()

    enemy.pathfinding.set_arrive_distance(5)
    enemy.pathfinding.set_speed(wander_speed)
    enemy.pathfinding.set_target_position(enemy.next_position)

    enemy.animation.travel_to_state(animation_state)


func _update(_delta: float) -> void:
    var movement_vector: Vector2 = enemy.pathfinding.get_velocity()
    enemy.movement.set_velocity(movement_vector)
    enemy.animation.set_animation_direction(movement_vector, animation_state)

    if enemy.pathfinding.navigation_agent.is_navigation_finished():
        change_state(EnemyStateId.IDLE)
        return

    if enemy.enemy_scanner.is_enemy_tracked():
        change_state(EnemyStateId.CHASE)
        return


func _exit() -> void:
    pass
