extends PlayerState


func _init() -> void:
    state_id = PlayerStateId.IDLE


func _enter() -> void:
    player.perform_movement(Vector2.ZERO, 0.0, false)
    player.play_animation(Player.AnimationState.IDLE)


func _update(_delta: float) -> void:
    if player.get_movement_input().length() > 0:
        change_state(PlayerState.PlayerStateId.MOVE)
    elif player.is_attack_triggered():
        change_state(PlayerState.PlayerStateId.ATTACK)
    elif player.is_roll_pressed():
        change_state(PlayerState.PlayerStateId.ROLL)
