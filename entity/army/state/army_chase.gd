extends ArmyState

@export var follow_threshold: float = 100


func _init() -> void:
    state_id = ArmyState.ArmyStateId.CHASE


func _enter() -> void:
    target.soft_collision.enabled = false
    target.pathfinding.set_arrive_distance(target.attack_range / 2)
    target.set_target_position(target.get_nearest_enemy().global_position)

    target.animation.travel_to_state(self.animation_state)


func _update(_delta: float) -> void:
    if not target.is_enemy_visible():
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    if target.is_enemy_attackable():
        change_state(ArmyState.ArmyStateId.ATTACK)
        return

    if target.get_distance_to_player() > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    target.set_target_position(target.get_nearest_enemy().global_position)
    target.movement.set_velocity(target.pathfinding.get_velocity())


func _exit() -> void:
    pass
