extends ArmyState

@export var follow_threshold: float = 50


func _init() -> void:
    state_id = ArmyState.ArmyStateId.IDLE


func _enter() -> void:
    # target.soft_collision.enabled = true
    target.movement.stop()

    target.animation.travel_to_state(self.animation_state)


func _update(_delta: float) -> void:
    if target.get_distance_to_player() > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    if target.enemy_scanner.is_enemy_visible():
        change_state(ArmyState.ArmyStateId.CHASE)
        return


func _exit() -> void:
    pass
