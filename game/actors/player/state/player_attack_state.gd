extends PlayerState

@export var attack_move_speed: float = 100.0

## Which weapon to fire (index into CombatModule.weapons).
@export var weapon_index: int = 0

## Which attack within that weapon to fire (index into WeaponData.attacks).
@export var attack_index: int = 0

var _attack_direction: Vector2 = Vector2.DOWN


func _init() -> void:
    state_id = PlayerStateId.ATTACK


func _enter() -> void:
    var target_pos := player.get_attack_target_position(weapon_index, attack_index)
    _attack_direction = target_pos - player.global_position

    if _attack_direction == Vector2.ZERO:
        _attack_direction = player.get_aim_direction()
    if _attack_direction == Vector2.ZERO:
        _attack_direction = Vector2.DOWN

    _attack_direction = _attack_direction.normalized()

    if not player.attack_finished.is_connected(_on_attack_finished):
        player.attack_finished.connect(_on_attack_finished)

    player.play_animation(Player.ANIM_ATTACK)
    player.set_facing_direction(_attack_direction, Player.ANIM_ATTACK)
    player.perform_attack(target_pos, weapon_index, attack_index)


func _physics_update(_delta: float) -> void:
    # Allow slight drift while attacking.
    var input_dir := player.get_move_input()
    if input_dir != Vector2.ZERO:
        player.set_movement_velocity(input_dir, attack_move_speed)
    else:
        player.stop_movement()


func _exit() -> void:
    if player.attack_finished.is_connected(_on_attack_finished):
        player.attack_finished.disconnect(_on_attack_finished)

    player.stop_movement()


func _on_attack_finished() -> void:
    player.end_attack()
    if player.get_move_input() != Vector2.ZERO:
        change_state(PlayerStateId.MOVE)
    else:
        change_state(PlayerStateId.IDLE)
