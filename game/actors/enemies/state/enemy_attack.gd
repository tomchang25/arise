extends EnemyState

@export var animation_state: StringName = Enemy.ANIM_ATTACK

## Which weapon to fire (index into CombatModule.weapons).
@export var weapon_index: int = 0

## Which attack within that weapon to fire (index into WeaponData.attacks).
@export var attack_index: int = 0

## Slow creep speed while repositioning during the attack state.
## Enemy nudges toward the player when distance > reach * 0.75,
## and stops when distance <= reach * 0.25.
@export var attack_speed: float = 30.0


func _init() -> void:
    state_id = EnemyStateId.ATTACK


func _enter() -> void:
    if not enemy.attack_finished.is_connected(_on_attack_finished):
        enemy.attack_finished.connect(_on_attack_finished)


func _exit() -> void:
    # Always end the attack on exit — ensures cooldown starts even if we
    # transition mid-swing (player escaped, state interrupted, enemy died).
    enemy.end_attack(weapon_index, attack_index)

    if enemy.attack_finished.is_connected(_on_attack_finished):
        enemy.attack_finished.disconnect(_on_attack_finished)


func _update(_delta: float) -> void:
    # Exit: player escaped deaggro zone.
    if enemy.is_player_outside_deaggro_range():
        change_state(EnemyStateId.BACK)
        return

    # Exit: player moved fully out of reach — hand off to chase.
    if not enemy.is_player_in_reach():
        change_state(EnemyStateId.CHASE)
        return

    var target := enemy.get_nearest_reachable_target()
    if target:
        # Slow creep: nudge toward the player when they're in the outer band
        # (reach * 0.75), stop when close enough (reach * 0.25).
        var reach := _get_reach_radius()
        if reach > 0.0:
            var dist := enemy.global_position.distance_to(target.global_position)
            var close_threshold := reach * 0.5
            var creep_threshold := reach * 0.75
            if dist > creep_threshold:
                enemy.move_to_position(target.global_position, attack_speed, close_threshold)
                enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), animation_state)
            elif dist <= close_threshold:
                enemy.stop_movement()

        # Fire when ready.
        if enemy.can_attack(weapon_index, attack_index):
            enemy.play_animation(animation_state)
            enemy.perform_attack(target.global_position, weapon_index, attack_index)
            enemy.set_facing_direction(enemy.global_position.direction_to(target.global_position), animation_state)


func _on_attack_finished() -> void:
    # Commit the cooldown for the swing that just finished.
    enemy.end_attack(weapon_index, attack_index)

# -------------------------
# Internal
# -------------------------


func _get_reach_radius() -> float:
    if enemy.reach_detection:
        return enemy.reach_detection.radius
    return 0.0
