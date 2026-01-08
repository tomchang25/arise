extends ArmyState

@export var animation_state: String = Army.AnimationState.MOVE
@export var follow_threshold: float = 100
@export var chase_speed := 50


func _init() -> void:
    state_id = ArmyStateId.CHASE


func _enter() -> void:
    target.play_animation(animation_state)


func _update(_delta: float) -> void:
    if not target.is_target_tracked() or target.get_distance_to_player() > follow_threshold:
        change_state(ArmyStateId.FOLLOW)
        return

    if target.enemy_scanner.is_enemy_attackable():
        change_state(ArmyStateId.ATTACK)
        return

    var nearest_enemy = target.get_nearest_target()
    if nearest_enemy:
        target.move_to_position(nearest_enemy.global_position, chase_speed, target.attack_range / 2)
        target.set_facing_direction(target.global_position.direction_to(nearest_enemy.global_position), animation_state)


func _exit() -> void:
    pass
