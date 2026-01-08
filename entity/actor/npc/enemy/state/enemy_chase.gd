extends EnemyState

@export var follow_threshold: float = 250
var animation_state: String = Enemy.AnimationState.MOVE


func _init() -> void:
    state_id = EnemyStateId.CHASE


func _enter() -> void:
    enemy.play_animation(animation_state, 1.5)


func _update(_delta: float) -> void:
    if not enemy.is_target_tracked() or enemy.get_distance_to_start() > follow_threshold:
        change_state(EnemyStateId.BACK)
        return

    if enemy.is_target_attackable():
        change_state(EnemyStateId.ATTACK)
        return

    var target = enemy.get_nearest_tracked_target()
    if target:
        enemy.move_to_position(target.global_position, enemy.chase_speed, enemy.attack_range / 2)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), animation_state)
