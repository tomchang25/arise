extends ArmyState

@export var follow_threshold: float = 50


func _init() -> void:
    state_id = ArmyState.ArmyStateId.IDLE


func _enter() -> void:
    target.soft_collision.enabled = true
    target.movement.stop()

    target.animation.travel_to_state(self.animation_state)


func _update(_delta: float) -> void:
    if target.global_position.distance_to(target.player.global_position) > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    # if target.is_enemy_visible():
    #     change_state(ArmyState.ArmyStateId.CHASE)
    #     return

    # target.velocity = target.soft_collision.soft_push_velocity


func _exit() -> void:
    pass
