extends PlayerState


func _init() -> void:
    state_id = PlayerStateId.IDLE


func _enter() -> void:
    player.stop_movement()

    player.play_animation(Player.ANIM_IDLE)
    player.set_facing_direction(player.animation_module.get_last_direction(), Player.ANIM_IDLE)


func _update(_delta: float) -> void:
    if player.consume_attack_request():
        change_state(PlayerStateId.ATTACK)
        return

    if player.consume_dodge_request():
        change_state(PlayerStateId.ROLL)
        return

    if player.has_auto_attack_target():
        change_state(PlayerStateId.ATTACK)
        return

    if player.get_move_input() != Vector2.ZERO:
        change_state(PlayerStateId.MOVE)
