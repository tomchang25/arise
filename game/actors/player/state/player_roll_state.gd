extends PlayerState

@export var roll_speed: float = 240.0

var _roll_direction: Vector2 = Vector2.ZERO


func _init() -> void:
    state_id = PlayerStateId.ROLL


func _enter() -> void:
    _roll_direction = player.get_move_input()

    if _roll_direction == Vector2.ZERO and player.animation_module:
        _roll_direction = player.animation_module.get_last_direction()
    if _roll_direction == Vector2.ZERO:
        _roll_direction = Vector2.DOWN

    _roll_direction = _roll_direction.normalized()

    if not player.roll_finished.is_connected(_on_roll_finished):
        player.roll_finished.connect(_on_roll_finished)

    player.play_animation(Player.ANIM_ROLL, 2.0)
    player.set_facing_direction(_roll_direction, Player.ANIM_ROLL)
    player.set_movement_velocity(_roll_direction, roll_speed)


func _physics_update(_delta: float) -> void:
    player.set_movement_velocity(_roll_direction, roll_speed)


func _exit() -> void:
    if player.roll_finished.is_connected(_on_roll_finished):
        player.roll_finished.disconnect(_on_roll_finished)

    player.stop_movement()


func _on_roll_finished() -> void:
    if player.get_move_input() != Vector2.ZERO:
        change_state(PlayerStateId.MOVE)
    else:
        change_state(PlayerStateId.IDLE)
