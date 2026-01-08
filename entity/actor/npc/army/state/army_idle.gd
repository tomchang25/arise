extends ArmyState

@export var follow_threshold: float = 50
@export var animation_state: String = Army.AnimationState.IDLE


func _init() -> void:
    state_id = ArmyStateId.IDLE


func _enter() -> void:
    target.stop_movement()
    target.play_animation(animation_state)


func _update(_delta: float) -> void:
    if target.get_distance_to_player() > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    if target.is_target_tracked():
        change_state(ArmyState.ArmyStateId.CHASE)
        return
