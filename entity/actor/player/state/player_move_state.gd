class_name PlayerMoveState
extends PlayerState

const INPUT_GRACE_TIME = 0.2
var _idle_timer: float = 0.0


func _init() -> void:
    state_id = PlayerStateId.MOVE


func _update(delta: float) -> void:
    var input = player.get_movement_input()

    # Handle Speed & Animation Speed
    var is_running = player.is_run_pressed()
    var current_speed = player.run_speed if is_running else player.walk_speed
    var anim_speed = 2.0 if is_running else 1.0

    player.perform_movement(input, current_speed, true)
    player.set_facing_direction(input)
    player.play_animation(Player.AnimationState.MOVE, anim_speed)

    # Transition: Idle with Grace Period
    if input.length() == 0:
        _idle_timer += delta
        if _idle_timer >= INPUT_GRACE_TIME:
            change_state(PlayerStateId.IDLE)
    else:
        _idle_timer = 0.0

    # Transitions: Action
    if player.is_roll_pressed():
        change_state(PlayerStateId.ROLL)
    elif player.is_attack_triggered():
        change_state(PlayerStateId.ATTACK)
