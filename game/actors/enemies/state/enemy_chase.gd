extends EnemyState

## How far the enemy can wander from home_position before giving up the chase.
@export var leash_distance: float = 300.0

## Minimum time between charge attempts. Starts counting after recovery ends.
@export var charge_cooldown: float = 3.0

var _charge_ready: bool = true
var _charge_cooldown_timer: float = 0.0


func _init() -> void:
    state_id = EnemyStateId.CHASE


func _enter() -> void:
    enemy.play_animation(Enemy.ANIM_MOVE, 1.5)


func _update(delta: float) -> void:
    # Tick charge cooldown
    if not _charge_ready:
        _charge_cooldown_timer -= delta
        if _charge_cooldown_timer <= 0.0:
            _charge_ready = true

    # Exit: player left deaggro zone
    if enemy.is_player_outside_deaggro_range():
        change_state(EnemyStateId.BACK)
        return

    # Exit: leash
    if enemy.get_distance_to_home() > leash_distance:
        change_state(EnemyStateId.LEASH_BACK)
        return

    # Transition: charge windup when player in reach and cooldown cleared
    if enemy.is_player_in_reach() and _charge_ready:
        _charge_ready = false
        _charge_cooldown_timer = charge_cooldown
        change_state(EnemyStateId.CHARGE_WINDUP)
        return

    # Move toward player
    var target := enemy.get_nearest_aggro_target()
    if target:
        var stop_dist := 0.0
        if enemy.reach_detection:
            stop_dist = enemy.reach_detection.radius * 0.5

        enemy.move_to_position(target.global_position, enemy.chase_speed, stop_dist)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), Enemy.ANIM_MOVE)
