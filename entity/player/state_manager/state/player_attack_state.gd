extends PlayerState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.ATTACK


func _enter() -> void:
    if not player.melee_attack.can_attack():
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return

    player.animation.travel_to_state(player.animation.ANIMATION_STATE_ATTACK)

    if player.nearest_enemy != null:
        player.animation.set_animation_direction(player.melee_attack.global_position.direction_to(player.nearest_enemy.global_position))
        player.melee_attack.aim_at(player.nearest_enemy.global_position)
    else:
        player.animation.set_animation_direction(player.melee_attack.get_local_mouse_position().normalized())
        player.melee_attack.aim_at(player.get_global_mouse_position())

    player.melee_attack.start_attack()

    if not player.animation.animation_finished.is_connected(_on_animation_finished):
        player.animation.animation_finished.connect(_on_animation_finished)


func _exit() -> void:
    if player.animation.animation_finished.is_connected(_on_animation_finished):
        player.animation.animation_finished.disconnect(_on_animation_finished)

    player.melee_attack.end_attack()


func _update(_delta: float) -> void:
    player.movement.update_direction()


func _on_animation_finished(anim_name: StringName) -> void:
    if player.animation.ANIMATION_STATE_ATTACK in anim_name:
        self.change_state(PlayerState.PlayerStateId.IDLE)
