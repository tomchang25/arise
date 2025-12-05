class_name PlayerMoveState
extends PlayerState

const INPUT_GRACE_TIME = 0.2

var _idle_timer: float = 0.0


func enter() -> void:
    super.enter()
    _idle_timer = 0.0


func update(delta: float) -> void:
    super.update(delta)

    if _check_idle(delta):
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return

    if player.movement.is_run_pressed():
        if not state_id == PlayerState.PlayerStateId.RUN:
            self.change_state(PlayerState.PlayerStateId.RUN)
            return
    else:
        if not state_id == PlayerState.PlayerStateId.WALK:
            self.change_state(PlayerState.PlayerStateId.WALK)
            return

    if player.movement.is_roll_pressed():
        self.change_state(PlayerState.PlayerStateId.ROLL)
        return

    # if (player.movement.is_attack_pressed() or player.nearest_enemy != null) and player.melee_attack.can_attack():
    #     self.change_state(PlayerState.PlayerStateId.ATTACK)
    #     return

    player.movement.set_direction_to_input()
    if player.movement.get_input_direction().length() > 0:
        player.animation.set_animation_direction(player.movement.get_input_direction())


func _check_idle(delta: float) -> bool:
    if player.movement.get_input_direction().length() > 0:
        _idle_timer = 0.0
        return false

    _idle_timer += delta
    if _idle_timer >= INPUT_GRACE_TIME:
        return true

    return false
