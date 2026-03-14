extends EnemyState

## How far the enemy can wander from home_position before giving up the chase.
## Acts as a leash — independent from the deaggro detection radius.
@export var leash_distance: float = 300.0


func _init() -> void:
    state_id = EnemyStateId.CHASE


func _enter() -> void:
    enemy.play_animation(Enemy.ANIM_MOVE, 1.5)


func _update(_delta: float) -> void:
    # Exit condition 1: player left the deaggro detection zone
    if enemy.is_player_outside_deaggro_range():
        change_state(EnemyStateId.BACK)
        return

    # Exit condition 2: enemy strayed too far from its spawn point (leash)
    if enemy.get_distance_to_home() > leash_distance:
        change_state(EnemyStateId.LEASH_BACK)
        return

    # Transition: close enough to attack
    if enemy.is_player_in_reach():
        change_state(EnemyStateId.ATTACK)
        return

    # Move toward player
    var target := enemy.get_nearest_aggro_target()
    if target:
        var stop_dist := 0.0
        if enemy.reach_detection:
            stop_dist = enemy.reach_detection.radius * 0.5

        enemy.move_to_position(target.global_position, enemy.chase_speed, stop_dist)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), Enemy.ANIM_MOVE)
