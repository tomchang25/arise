extends EnemyState

## How far the enemy can wander from home_position before giving up the chase.
@export var leash_distance: float = 300.0

## Minimum time between charge attempts. Starts counting after recovery ends.
@export var chase_speed: float = 150.0


func _init() -> void:
    state_id = EnemyStateId.CHASE


func _enter() -> void:
    enemy.play_animation(Enemy.ANIM_MOVE, 1.5)


func _update(_delta: float) -> void:
    # Exit: player left deaggro zone
    if enemy.is_player_outside_deaggro_range():
        change_state(EnemyStateId.BACK)
        return

    # Exit: leash
    if enemy.get_distance_to_home() > leash_distance:
        change_state(EnemyStateId.LEASH_BACK)
        return

    if enemy.is_player_in_reach():
        change_state(EnemyStateId.ATTACK)
        return

    # Move toward player
    var target := enemy.get_nearest_aggro_target()
    if target:
        var stop_dist := 0.0
        if enemy.reach_detection:
            stop_dist = enemy.reach_detection.radius * 0.5

        enemy.move_to_position(target.global_position, chase_speed, stop_dist)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), Enemy.ANIM_MOVE)
