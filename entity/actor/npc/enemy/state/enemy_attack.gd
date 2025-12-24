extends EnemyState

# func _init() -> void:
#     state_id = EnemyStateId.ATTACK

# func _enter() -> void:
#     print("attack")

# func _update(_delta: float) -> void:
#     change_state(EnemyStateId.IDLE)

# func _exit() -> void:
#     pass

@export var follow_threshold: float = 250
@export var attack_speed: float = 50
@export var animation_state: String = "Attack"


func _init() -> void:
    state_id = EnemyStateId.ATTACK


func _enter() -> void:
    enemy.animation.travel_to_state(animation_state)
    # enemy.pathfinding.enabled = false
    # enemy.movement.stop()

    enemy.pathfinding.set_arrive_distance(enemy.attack_range / 2)
    enemy.pathfinding.set_speed(attack_speed)


func _exit() -> void:
    pass


func _update(_delta: float) -> void:
    if not enemy.enemy_scanner.is_enemy_tracked():
        change_state(EnemyStateId.BACK)
        return

    if enemy.get_distance_to_start() > follow_threshold:
        change_state(EnemyStateId.BACK)
        return

    if not enemy.enemy_scanner.is_enemy_attackable():
        change_state(EnemyStateId.CHASE)
        return

    var nearest_enemy: Node2D = enemy.enemy_scanner.get_nearest_attackable_enemy()
    var enemy_position: Vector2 = nearest_enemy.global_position

    if enemy.attack_handler.can_attack():
        if nearest_enemy:
            enemy.attack_handler.start_attack(enemy_position)
            enemy.animation.set_animation_direction(enemy.global_position.direction_to(enemy_position), self.animation_state)

    # if enemy.pathfinding.navigation_agent.is_navigation_finished():
    #     enemy.movement.stop()
    # else:
    enemy.pathfinding.set_target_position(enemy_position)
    enemy.movement.set_velocity(enemy.pathfinding.get_velocity())
