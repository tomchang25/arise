class_name PlayerMoveState
extends PlayerState

const INPUT_GRACE_TIME = 0.2

@export var run_speed: float = 150
@export var walk_speed: float = 100

var _idle_timer: float = 0.0


func _init() -> void:
    state_id = PlayerState.PlayerStateId.MOVE


func _enter() -> void:
    _idle_timer = 0.0
    player.animation.travel_to_state(player.animation.ANIMATION_STATE_MOVE)


func _update(delta: float) -> void:
    if _check_idle(delta):
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return

    if player.player_input.is_run_pressed():
        player.movement.set_speed(run_speed)
        player.animation.set_time_scale(2.0)
    else:
        player.movement.set_speed(walk_speed)
        player.animation.set_time_scale(1.0)

    if player.player_input.is_roll_pressed():
        self.change_state(PlayerState.PlayerStateId.ROLL)
        return

    if (
        (player.player_input.is_attack_pressed() or player.nearest_enemy != null)
        and (not player.player_input.is_run_pressed())
        and player.melee_attack.can_attack()
    ):
        self.change_state(PlayerState.PlayerStateId.ATTACK)
        return

    var input_direction: Vector2 = player.player_input.get_movement_direction()
    player.movement.set_direction(input_direction)

    if input_direction.length() > 0:
        player.animation.set_animation_direction(input_direction)


func _check_idle(delta: float) -> bool:
    if player.player_input.get_movement_direction().length() > 0:
        _idle_timer = 0.0
        return false

    _idle_timer += delta
    if _idle_timer >= INPUT_GRACE_TIME:
        return true

    return false
