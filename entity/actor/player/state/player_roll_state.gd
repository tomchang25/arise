extends PlayerState


func _init() -> void:
    state_id = PlayerStateId.ROLL


func _enter() -> void:
    var input_direction: Vector2 = player.get_movement_input()
    if input_direction == Vector2.ZERO:
        input_direction = player.get_last_direction()

    player.perform_movement(input_direction, player.roll_speed, false)
    player.play_animation(Player.AnimationState.ROLL, 2.0)

    player.roll_finished.connect(_on_finished)


func _exit() -> void:
    if player.roll_finished.is_connected(_on_finished):
        player.roll_finished.disconnect(_on_finished)


func _on_finished() -> void:
    change_state(PlayerStateId.IDLE)
