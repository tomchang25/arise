extends PlayerState

@export var roll_speed: float = 300


func _init() -> void:
    state_id = PlayerState.PlayerStateId.ROLL


func _enter() -> void:
    var direction: Vector2 = player.player_input.get_movement_direction()

    player.movement.set_speed(roll_speed)
    player.movement.set_direction(direction)

    player.animation.travel_to_state(player.animation.ANIMATION_STATE_ROLL)
    player.animation.set_animation_direction(direction)
    player.animation.set_time_scale(2.0)


func _exit() -> void:
    player.animation.set_time_scale(1.0)


func _update(_delta: float) -> void:
    pass


func _on_animation_finished(anim_name: StringName) -> void:
    if player.animation.ANIMATION_STATE_ROLL in anim_name:
        self.change_state(PlayerState.PlayerStateId.IDLE)
