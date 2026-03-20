## Performs a melee (detached) attack when the player is in reach and the weapon is ready.
## Keeps the enemy slowly repositioning toward the player while in attack range.
## Returns RUNNING while in reach, FAILURE when the player moves out of reach.
class_name MeleeAttackAction
extends ActionLeaf

@export var weapon_index: int = 0
@export var attack_index: int = 0
## Slow creep speed while repositioning during the attack.
@export var attack_speed: float = 30.0


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE

    if not enemy.is_player_in_reach():
        enemy.stop_movement()
        return FAILURE

    var target := enemy.get_nearest_reachable_target()
    if target:
        # Slow creep: nudge toward the player when they're in the outer band,
        # stop when close enough.
        var reach := _get_reach_radius(enemy)
        if reach > 0.0:
            var dist := enemy.global_position.distance_to(target.global_position)
            var close_threshold := reach * 0.5
            var creep_threshold := reach * 0.75
            if dist > creep_threshold:
                enemy.move_to_position(target.global_position, attack_speed, close_threshold)
                enemy.set_facing_direction(
                    enemy.global_position.direction_to(target.global_position),
                    Enemy.ANIM_ATTACK,
                )
            elif dist <= close_threshold:
                enemy.stop_movement()

        # Fire when ready. Auto-end immediately to start the cooldown timer.
        if enemy.can_attack(weapon_index, attack_index):
            enemy.play_animation(Enemy.ANIM_ATTACK)
            enemy.perform_attack(target.global_position, weapon_index, attack_index)
            enemy.end_attack(weapon_index, attack_index)
            enemy.set_facing_direction(
                enemy.global_position.direction_to(target.global_position),
                Enemy.ANIM_ATTACK,
            )

    return RUNNING


func _get_reach_radius(enemy: Enemy) -> float:
    if enemy.reach_detection:
        return enemy.reach_detection.radius
    return 0.0
