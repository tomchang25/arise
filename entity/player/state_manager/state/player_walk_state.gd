extends PlayerMoveState


func _init() -> void:
    state_id = PlayerState.PlayerStateId.WALK


func _enter() -> void:
    player.movement.set_walk_speed()
    player.animation.travel_to_state(player.animation.ANIMATION_STATE_MOVE)


func _update(_delta: float) -> void:
    if (player.movement.is_attack_pressed() or player.nearest_enemy != null) and player.melee_attack.can_attack():
        self.change_state(PlayerState.PlayerStateId.ATTACK)
        return
