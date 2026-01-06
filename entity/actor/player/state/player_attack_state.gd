extends PlayerState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.ATTACK


func _enter() -> void:
    player.play_animation(Player.AnimationState.ATTACK)

    var face_dir = player.get_attack_target_direction()
    player.set_facing_direction(face_dir)

    var target = player.get_nearest_attackable_enemy()
    var target_pos = target.global_position if target else player.get_global_mouse_position()
    player.start_attack_logic(target_pos)

    player.attack_finished.connect(_on_finished)


func _update(_delta: float) -> void:
    var movement_input = player.get_movement_input()
    player.perform_movement(movement_input, player.attack_speed, false)


func _exit() -> void:
    if player.attack_finished.is_connected(_on_finished):
        player.attack_finished.disconnect(_on_finished)
    player.end_attack_logic()


func _on_finished() -> void:
    change_state(PlayerStateId.IDLE)
