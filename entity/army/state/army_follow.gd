extends ArmyState

@export var check_player_timer_interval: float = 0.1

var check_player_timer = 0
var prev_player_position: Vector2


func _init() -> void:
    state_id = ArmyState.ArmyStateId.FOLLOW


func _enter() -> void:
    target.soft_collision.enabled = false
    target.follow_player.set_arrive_distance(20)


func _update(delta: float) -> void:
    _update_player_position(delta)

    var movement_vector: Vector2 = target.follow_player.movement_vector
    target.velocity = movement_vector

    if not target.is_too_far_from_player():
        if movement_vector == Vector2.ZERO:
            change_state(ArmyState.ArmyStateId.IDLE)
            return

        if target.is_enemy_visible():
            change_state(ArmyState.ArmyStateId.CHASE)
            return


func _exit() -> void:
    pass


func _update_player_position(delta: float) -> void:
    if check_player_timer > check_player_timer_interval:
        check_player_timer = 0

        if prev_player_position.distance_to(target.player.global_position) > 10:
            prev_player_position = target.player.global_position
            target.follow_player.set_target(target.player.global_position)
    check_player_timer += delta
