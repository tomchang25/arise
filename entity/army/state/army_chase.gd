extends ArmyState

@export var attack_range: float = 50


func _init() -> void:
    state_id = ArmyState.ArmyStateId.CHASE


func _enter() -> void:
    target.soft_collision.enabled = false
    target.follow_player.set_arrive_distance(10)


func _update(_delta: float) -> void:
    if not target.is_enemy_visible() or target.is_too_far_from_player():
        change_state(ArmyState.ArmyStateId.IDLE)
        return

    var nearest_enemy: Node = null
    for enemy in target.enemies_in_range:
        if (
            nearest_enemy == null
            or target.global_position.distance_to(enemy.global_position) < target.global_position.distance_to(nearest_enemy.global_position)
        ):
            nearest_enemy = enemy

    target.follow_player.set_target(nearest_enemy.global_position)

    # var distance_to_enemy: float = target.global_position.distance_to(nearest_enemy.global_position)
    # if distance_to_enemy <= attack_range:
    #     change_state(ArmyState.ArmyStateId.ATTACK)
    #     return

    target.velocity = target.follow_player.movement_vector


func _exit() -> void:
    pass
