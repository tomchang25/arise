extends PlayerState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.ROLL


func _enter() -> void:
    player.movement.set_roll_speed()
    player.movement.update_direction()

    player.animation.travel_to_state(player.animation.ANIMATION_STATE_ROLL)
    player.animation.set_animation_direction(player.movement.get_input_direction())

    if not player.animation.animation_finished.is_connected(_on_animation_finished):
        player.animation.animation_finished.connect(_on_animation_finished)


func _exit() -> void:
    if player.animation.animation_finished.is_connected(_on_animation_finished):
        player.animation.animation_finished.disconnect(_on_animation_finished)


func _update(_delta: float) -> void:
    pass


func _on_animation_finished(anim_name: StringName) -> void:
    if player.animation.ANIMATION_STATE_ROLL in anim_name:
        self.change_state(PlayerState.PlayerStateId.IDLE)
