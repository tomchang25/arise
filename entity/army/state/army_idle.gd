extends ArmyState


func _init() -> void:
    state_id = ArmyState.ArmyStateId.IDLE


func _enter() -> void:
    target.soft_collision.enabled = true
    target.velocity = Vector2.ZERO


func _update(_delta: float) -> void:
    # if target.is_too_far_from_player():
    #     change_state(ArmyState.ArmyStateId.FOLLOW)
    #     return

    # if target.is_enemy_visible():
    #     change_state(ArmyState.ArmyStateId.CHASE)
    #     return

    target.velocity = target.soft_collision.soft_push_velocity


func _exit() -> void:
    pass
