extends PlayerState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.RUN


func _enter() -> void:
    player.movement.set_run_speed()
    player.animation.travel_to_state(player.animation.ANIMATION_STATE_MOVE)
    player.animation.set_time_scale(2.0)


func _exit() -> void:
    player.animation.set_time_scale(1.0)


func _update(_delta: float) -> void:
    if player.movement.get_input_direction().length() == 0:
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return

    if not player.movement.is_run_pressed():
        self.change_state(PlayerState.PlayerStateId.WALK)
        return

    if player.movement.is_roll_pressed():
        self.change_state(PlayerState.PlayerStateId.ROLL)
        return

    if player.movement.is_attack_pressed() and player.melee_attack.can_attack():
        self.change_state(PlayerState.PlayerStateId.ATTACK)
        return

    player.movement.update_direction()
    player.animation.set_animation_direction(player.movement.get_input_direction())
