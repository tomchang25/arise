extends EnemyState

@export var move_speed: float = 50
@export var animation_state: String = "Move"


func _init() -> void:
    state_id = EnemyStateId.BACK


func _enter() -> void:
    enemy.pathfinding.set_arrive_distance(5)
    enemy.pathfinding.set_speed(move_speed)
    enemy.pathfinding.set_target_position(enemy.start_position)

    enemy.animation.travel_to_state(animation_state)


func _update(_delta: float) -> void:
    enemy.movement.set_velocity(enemy.pathfinding.get_velocity())

    enemy.animation.set_animation_direction(enemy.global_position.direction_to(enemy.start_position), animation_state)

    if enemy.pathfinding.navigation_agent.is_navigation_finished():
        change_state(EnemyStateId.IDLE)
        return

    # TODO: This might make enemy stuck in Chase and Back state in border
    # if enemy.enemy_scanner.is_enemy_visible():
    #     change_state(EnemyStateId.CHASE)
    #     return


func _exit() -> void:
    pass
