extends ArmyState

@export var animation_state: StringName = Actor.ANIM_ATTACK
@export var follow_threshold: float = 200


func _init() -> void:
    state_id = ArmyState.ArmyStateId.ATTACK


func _enter() -> void:
    target.play_animation(animation_state)
    target.stop_movement()


func _update(_delta: float) -> void:
    if not target.is_target_tracked() or target.get_distance_to_anchor() > follow_threshold:
        change_state(ArmyStateId.FOLLOW)
        return

    if not target.is_target_attackable():
        change_state(ArmyState.ArmyStateId.CHASE)
        return

    var nearest_enemy = target.get_nearest_attackable_target()
    if nearest_enemy:
        target.perform_attack(nearest_enemy.global_position)
        target.set_facing_direction(target.global_position.direction_to(nearest_enemy.global_position), animation_state)
