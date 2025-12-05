extends PlayerMoveState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.RUN


func _enter() -> void:
    player.movement.set_run_speed()
    player.animation.travel_to_state(player.animation.ANIMATION_STATE_MOVE)
    player.animation.set_time_scale(2.0)


func _exit() -> void:
    player.animation.set_time_scale(1.0)
