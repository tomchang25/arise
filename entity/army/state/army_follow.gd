extends ArmyState

@export var check_player_timer_interval: float = 0.1
@export var move_speed: float = 100
@export var min_distance_to_player: float = 25

var check_player_timer = 0
# var prev_player_position: Vector2


func _init() -> void:
    state_id = ArmyState.ArmyStateId.FOLLOW


func _enter() -> void:
    target.soft_collision.enabled = false
    target.pathfinding.set_arrive_distance(5)
    target.pathfinding.set_speed(move_speed)
    # target.set_target_position(target.player.global_position)
    target.update_grid_position()

    target.animation.travel_to_state(self.animation_state)


func _update(delta: float) -> void:
    _update_player_position(delta)

    var movement_vector: Vector2 = target.pathfinding.get_velocity()
    target.movement.set_velocity(movement_vector)

    target.animation.set_animation_direction(movement_vector, self.animation_state)

    if target.get_distance_to_player() < min_distance_to_player:
        # if movement_vector == Vector2.ZERO:
        #     change_state(ArmyState.ArmyStateId.IDLE)
        #     return

        if target.is_enemy_visible():
            change_state(ArmyState.ArmyStateId.CHASE)
            return

    if target.pathfinding.navigation_agent.is_navigation_finished():
        change_state(ArmyState.ArmyStateId.IDLE)
        return


func _exit() -> void:
    pass


func _update_player_position(delta: float) -> void:
    if check_player_timer > check_player_timer_interval:
        check_player_timer = 0

        # if prev_player_position.distance_to(target.player.global_position) > 10:
        # prev_player_position = target.player.global_position
        # target.set_target_position(target.player.global_position)

        target.update_grid_position()

    check_player_timer += delta
