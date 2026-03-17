extends EnemyState

@export var animation_state: StringName = Enemy.ANIM_ATTACK

## Which weapon to fire (index into CombatModule.weapons).
@export var weapon_index: int = 0

## Which attack within that weapon to fire (index into WeaponData.attacks).
@export var attack_index: int = 0


func _init() -> void:
    state_id = EnemyStateId.ATTACK


func _enter() -> void:
    enemy.play_animation(animation_state)
    enemy.stop_movement()


func _update(_delta: float) -> void:
    # Exit: player escaped deaggro zone.
    if enemy.is_player_outside_deaggro_range():
        change_state(EnemyStateId.BACK)
        return

    # Player moved out of reach — chase again.
    if not enemy.is_player_in_reach():
        change_state(EnemyStateId.CHASE)
        return

    var target := enemy.get_nearest_reachable_target()
    if target and enemy.can_attack(weapon_index, attack_index):
        enemy.perform_attack(target.global_position, weapon_index, attack_index)
        enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), animation_state)
