extends PlayerState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.IDLE


func _enter() -> void:
    player.movement.stop()
    player.animation.travel_to_state(self.animation_state)

    player.animation.set_as_prev_animation_direction(self.animation_state)


func _update(_delta: float) -> void:
    if player.player_input.get_movement_direction().length() > 0:
        self.change_state(PlayerState.PlayerStateId.MOVE)
        return

    if (player.player_input.is_attack_pressed() or player.nearest_enemy != null) and player.melee_attack.can_attack():
        self.change_state(PlayerState.PlayerStateId.ATTACK)
        return
