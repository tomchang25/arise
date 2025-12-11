extends ArmyState

@export var follow_threshold: float = 100


func _init() -> void:
    state_id = ArmyState.ArmyStateId.CHASE


func _enter() -> void:
    target.soft_collision.enabled = false
    target.pathfinding.set_arrive_distance(10)


func _update(_delta: float) -> void:
    if not target.is_enemy_visible():
        change_state(ArmyState.ArmyStateId.IDLE)
        return

    var nearest_enemy: Node = null
    for enemy in target.enemies_in_range:
        if (
            nearest_enemy == null
            or target.global_position.distance_to(enemy.global_position) < target.global_position.distance_to(nearest_enemy.global_position)
        ):
            nearest_enemy = enemy

    target.pathfinding.set_target(nearest_enemy)
    target.movement.set_velocity(target.pathfinding.get_velocity())

    if target.attack_handler.is_in_range(nearest_enemy.global_position):
        print("Attack")
        # change_state(ArmyState.ArmyStateId.ATTACK)
        # return

    if target.global_position.distance_to(target.player.global_position) > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return


func _exit() -> void:
    pass
