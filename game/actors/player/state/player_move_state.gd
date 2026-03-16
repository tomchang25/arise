extends PlayerState

@export var walk_speed: float = 180.0
@export var run_speed: float = 240.0
@export var idle_grace_time: float = 0.08

var _idle_timer := 0.0


func _init() -> void:
    state_id = PlayerStateId.MOVE


func _enter() -> void:
    _idle_timer = 0.0

    player.play_animation(Player.ANIM_MOVE)

    player.set_facing_direction(player.animation_module.get_last_direction(), Player.ANIM_MOVE)


func _physics_update(delta: float) -> void:
    var input_dir := player.get_move_input()
    var speed := run_speed if player.is_run_pressed() else walk_speed

    if input_dir != Vector2.ZERO:
        player.set_movement_velocity(input_dir, speed)
        player.set_facing_direction(input_dir, Player.ANIM_MOVE)
        _idle_timer = 0.0
    else:
        player.stop_movement()
        _idle_timer += delta


func _update(_delta: float) -> void:
    if player.consume_dodge_request():
        change_state(PlayerStateId.ROLL)
        return

    if not player.is_run_pressed():
        if player.consume_attack_request() or player.has_auto_attack_target():
            change_state(PlayerStateId.ATTACK)
            return

    if _idle_timer >= idle_grace_time:
        change_state(PlayerStateId.IDLE)


func _exit() -> void:
    player.stop_movement()
