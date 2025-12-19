extends ArmyState

@export var follow_threshold: float = 200


func _init() -> void:
    state_id = ArmyState.ArmyStateId.ATTACK


func _enter() -> void:
    target.animation.travel_to_state(self.animation_state)
    target.pathfinding.enabled = false
    target.movement.stop()


func _exit() -> void:
    target.pathfinding.enabled = true


func _update(_delta: float) -> void:
    if not target.is_enemy_visible():
        # change_state(ArmyState.ArmyStateId.IDLE)
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    if not target.is_enemy_attackable():
        change_state(ArmyState.ArmyStateId.CHASE)
        return

    if target.get_distance_to_player() > follow_threshold:
        change_state(ArmyState.ArmyStateId.FOLLOW)
        return

    if target.attack_handler.can_attack():
        var enemy_position: Vector2 = target.get_nearest_enemy().global_position

        if target.attack_handler.is_in_range(enemy_position):
            target.attack_handler.start_attack(enemy_position)
            target.animation.set_animation_direction(target.global_position.direction_to(enemy_position), self.animation_state)
