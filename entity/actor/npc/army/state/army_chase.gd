extends ArmyState

@export var follow_threshold: float = 100
@export var chase_speed := 50


func _init() -> void:
    state_id = ArmyStateId.CHASE
    animation_state = "Move"


func _enter() -> void:
    # target.soft_collision.enabled = false
    target.pathfinding.set_arrive_distance(target.attack_range / 2)
    target.pathfinding.set_speed(chase_speed)
    target.animation.travel_to_state(self.animation_state)


func _update(_delta: float) -> void:
    if not target.enemy_scanner.is_enemy_tracked():
        change_state(ArmyStateId.FOLLOW)
        return

    if target.enemy_scanner.is_enemy_attackable():
        change_state(ArmyStateId.ATTACK)
        return

    if target.get_distance_to_player() > follow_threshold:
        change_state(ArmyStateId.FOLLOW)
        return

    var nearest_enemy: Node2D = target.enemy_scanner.get_nearest_tracked_enemy()
    if nearest_enemy:
        var enemy_position: Vector2 = nearest_enemy.global_position

        target.pathfinding.set_target_position(enemy_position)
        target.animation.set_animation_direction(target.global_position.direction_to(enemy_position), animation_state)
        target.movement.set_velocity(target.pathfinding.get_velocity())

        print(nearest_enemy)


func _exit() -> void:
    pass
