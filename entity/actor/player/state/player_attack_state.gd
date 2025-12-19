extends PlayerState

@export var attack_speed: float = 50
var target_position: Vector2


func _init() -> void:
    state_id = PlayerState.PlayerStateId.ATTACK


func _enter() -> void:
    if not player.melee_attack.can_attack():
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return

    player.movement.set_speed(attack_speed)

    player.animation.travel_to_state(self.animation_state)

    if player.nearest_enemy != null:
        target_position = player.nearest_enemy.global_position
    else:
        target_position = player.get_global_mouse_position()

    player.attack(target_position)


func _update(_delta: float) -> void:
    player.melee_attack.aim_at(target_position)

    var attack_direction: Vector2 = player.melee_attack.global_position.direction_to(target_position)
    player.animation.set_animation_direction(attack_direction, self.animation_state)

    var movement_direction: Vector2 = player.player_input.get_movement_direction()
    player.movement.set_direction(movement_direction)


func _on_animation_finished(anim_name: StringName) -> void:
    if self.animation_state in anim_name:
        player.melee_attack.end_attack()
        self.change_state(PlayerState.PlayerStateId.IDLE)
        return
