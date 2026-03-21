## Shared chase state for all actors.
##
## Moves toward the nearest detected target. Exit conditions differ by data flags:
##   has_deaggro   → exit to RETURN_TO_ANCHOR when target leaves deaggro zone (Enemy)
##   leash_distance > 0 → exit to RETURN_TO_ANCHOR when too far from anchor
##   (no flags)    → exit to RETURN_TO_ANCHOR when no target or anchor too far (Army)
##
## Transitions:
##   → RETURN_TO_ANCHOR  if deaggro'd, leashed, or no target while far from anchor
##   → ATTACK            if target enters reach zone
extends ActorState

@export var chase_speed: float = 150.0
## Distance threshold used when has_deaggro is false (Army-like actors).
@export var follow_threshold: float = 100.0


func _init() -> void:
    state_id = ActorStateId.CHASE


func _enter() -> void:
    actor.play_animation(Actor.ANIM_MOVE, 1.5)


func _update(_delta: float) -> void:
    # Leash check — return home if too far from anchor.
    var leash := _get_leash_distance()
    if leash > 0.0 and actor.get_distance_to_anchor() > leash:
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # Deaggro check (Enemy with deaggro zone).
    if _has_deaggro() and _is_deaggrod():
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # Distance-based disengage (Army-like actors without deaggro).
    if not _has_deaggro():
        var no_target := not _is_aggro_triggered()
        var too_far := actor.get_distance_to_anchor() > follow_threshold
        if no_target or too_far:
            change_state(ActorStateId.RETURN_TO_ANCHOR)
            return

    # Target within reach → attack.
    if actor.is_target_in_reach():
        change_state(ActorStateId.ATTACK)
        return

    # Move toward target.
    var target := _get_nearest_target()
    if target:
        var stop_dist := 0.0
        if actor.reach_detection:
            stop_dist = actor.reach_detection.radius * 0.5
        actor.move_to_position(target.global_position, chase_speed, stop_dist)
        actor.set_facing_direction(actor.global_position.direction_to(target.global_position), Actor.ANIM_MOVE)

# -------------------------
# Internal helpers
# -------------------------


func _is_aggro_triggered() -> bool:
    var army := actor as Army
    if army:
        return army.is_target_tracked()
    var enemy := actor as Enemy
    if enemy:
        return enemy.is_player_in_aggro_range()
    return false


func _is_deaggrod() -> bool:
    var enemy := actor as Enemy
    if enemy:
        return enemy.is_player_outside_deaggro_range()
    return false


func _has_deaggro() -> bool:
    var army := actor as Army
    if army and army.data:
        return army.data.has_deaggro
    var enemy := actor as Enemy
    if enemy and enemy.data:
        return enemy.data.has_deaggro
    return false


func _get_leash_distance() -> float:
    var army := actor as Army
    if army and army.data:
        return army.data.leash_distance
    var enemy := actor as Enemy
    if enemy and enemy.data:
        return enemy.data.leash_distance
    return 0.0


func _get_nearest_target() -> Node2D:
    var army := actor as Army
    if army:
        return army.get_nearest_tracked_target()
    var enemy := actor as Enemy
    if enemy:
        return enemy.get_nearest_aggro_target()
    return null
