extends EnemyState

@export var animation_state: StringName = Enemy.ANIM_ATTACK


func _init() -> void:
    state_id = EnemyStateId.ATTACK


func _enter() -> void:
    enemy.play_animation(animation_state)
    enemy.stop_movement()


func _update(_delta: float) -> void:
    # Exit: player escaped deaggro zone
    if enemy.is_player_outside_deaggro_range():
        change_state(EnemyStateId.BACK)
        return

    # Player moved out of reach — chase again
    if not enemy.is_player_in_reach():
        change_state(EnemyStateId.CHASE)
        return

    var target := enemy.get_nearest_reachable_target()
    if target:
        enemy.perform_attack(target.global_position)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), animation_state)
