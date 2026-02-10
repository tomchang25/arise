extends EnemyState

@export var follow_threshold: float = 250
@export var animation_state: String = Enemy.AnimationState.ATTACK


func _init() -> void:
    state_id = EnemyStateId.ATTACK


func _enter() -> void:
    enemy.play_animation(animation_state)
    enemy.stop_movement()


func _update(_delta: float) -> void:
    if not enemy.is_target_tracked() or enemy.get_distance_to_start() > follow_threshold:
        change_state(EnemyStateId.BACK)
        return

    if not enemy.is_target_attackable():
        change_state(EnemyStateId.CHASE)
        return

    var target = enemy.get_nearest_attackable_target()
    if target:
        enemy.perform_attack(target.global_position)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), animation_state)
