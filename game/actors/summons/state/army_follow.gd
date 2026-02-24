extends ArmyState

# @export var check_player_timer_interval: float = 0.1
@export var animation_state: String = Army.AnimationState.MOVE
@export var move_speed: float = 100
@export var min_distance_to_player: float = 25

# var check_player_timer = 0
# var prev_player_position: Vector2


func _init() -> void:
    state_id = ArmyStateId.FOLLOW


func _enter() -> void:
    target.play_animation(animation_state)


func _update(_delta: float) -> void:
    # _update_player_position(delta)
    # Use the centralized movement API
    target.move_to_position(target.player.global_position + target.grid_position, move_speed, 5)

    # Update animation based on pathfinding velocity
    var velocity = target.pathfinding.get_velocity()
    target.set_facing_direction(velocity, animation_state)

    # Check for nearby enemies while following
    if target.get_distance_to_player() < min_distance_to_player:
        if target.is_target_tracked():
            change_state(ArmyState.ArmyStateId.CHASE)
            return

    if target.is_navigation_finished():
        change_state(ArmyState.ArmyStateId.IDLE)
        return
