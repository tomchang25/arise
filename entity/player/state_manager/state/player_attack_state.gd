extends PlayerState

var target_position: Vector2


func _init() -> void:
    state_id = PlayerState.PlayerStateId.ATTACK


func _enter() -> void:
    if not player.melee_attack.can_attack():
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return

    player.movement.set_walk_speed()

    player.animation.travel_to_state(player.animation.ANIMATION_STATE_ATTACK)

    if player.nearest_enemy != null:
        target_position = player.nearest_enemy.global_position
    else:
        target_position = player.get_global_mouse_position()

    player.attack(target_position)
    player.animation.set_animation_direction(player.melee_attack.global_position.direction_to(target_position))

    if not player.animation.animation_finished.is_connected(_on_animation_finished):
        player.animation.animation_finished.connect(_on_animation_finished)


func _exit() -> void:
    if player.animation.animation_finished.is_connected(_on_animation_finished):
        player.animation.animation_finished.disconnect(_on_animation_finished)


func _update(_delta: float) -> void:
    player.melee_attack.aim_at(target_position)
    player.animation.set_animation_direction(player.melee_attack.global_position.direction_to(target_position))
    player.movement.set_direction_to_input()


func _on_animation_finished(anim_name: StringName) -> void:
    if player.animation.ANIMATION_STATE_ATTACK in anim_name:
        self.change_state(PlayerState.PlayerStateId.IDLE)
