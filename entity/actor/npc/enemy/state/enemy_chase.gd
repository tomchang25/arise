extends EnemyState

@export var follow_threshold: float = 250
@export var chase_speed := 100
@export var animation_state: String = "Move"


func _init() -> void:
    state_id = EnemyStateId.CHASE


func _enter() -> void:
    enemy.pathfinding.set_target_position(enemy.next_position)
    enemy.pathfinding.set_arrive_distance(enemy.attack_range / 2)
    enemy.pathfinding.set_speed(chase_speed)
    enemy.animation.travel_to_state(animation_state)


func _update(_delta: float) -> void:
    if not enemy.enemy_scanner.is_enemy_tracked():
        change_state(EnemyStateId.BACK)
        return

    if enemy.get_distance_to_start() > follow_threshold:
        change_state(EnemyStateId.BACK)
        return

    if enemy.enemy_scanner.is_enemy_attackable():
        change_state(EnemyStateId.ATTACK)
        return

    var nearest_enemy: Node2D = enemy.enemy_scanner.get_nearest_tracked_enemy()
    if nearest_enemy:
        var enemy_position: Vector2 = nearest_enemy.global_position

        enemy.pathfinding.set_target_position(enemy_position)
        enemy.animation.set_animation_direction(enemy.global_position.direction_to(enemy_position), animation_state)
        enemy.movement.set_velocity(enemy.pathfinding.get_velocity())


func _exit() -> void:
    pass
