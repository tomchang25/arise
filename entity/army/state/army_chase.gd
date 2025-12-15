extends ArmyState

@export var follow_threshold: float = 100


func _init() -> void:
    state_id = ArmyState.ArmyStateId.CHASE


func _enter() -> void:
    target.soft_collision.enabled = false
    target.pathfinding.set_arrive_distance(10)


func _update(_delta: float) -> void:
    if not target.is_enemy_visible():
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    if target.is_enemy_attackable():
        change_state(ArmyState.ArmyStateId.ATTACK)
        return

    if target.global_position.distance_to(target.player.global_position) > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    target.pathfinding.set_target(target.get_nearest_enemy())
    target.movement.set_velocity(target.pathfinding.get_velocity())


func _exit() -> void:
    pass
