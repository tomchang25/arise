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
@export var move_update_interval: float = 0.1

var _move_timer: float = 0.0


func _init() -> void:
    state_id = ActorStateId.CHASE


func _enter() -> void:
    actor.play_animation(Actor.ANIM_MOVE, 1.5)


func _update(delta: float) -> void:
    # Leash check — return home if too far from anchor.
    if actor.get_leash_distance() > 0.0 and actor.get_distance_to_anchor() > actor.get_leash_distance():
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # Deaggro check (Enemy with deaggro zone).
    if actor.has_deaggro() and actor.is_deaggro_active():
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # Distance-based disengage (Army-like actors without deaggro).
    if not actor.has_deaggro():
        var no_target := not actor.is_aggro_active()
        var too_far := actor.get_distance_to_anchor() > follow_threshold
        if no_target or too_far:
            change_state(ActorStateId.RETURN_TO_ANCHOR)
            return

    # Target within reach → attack.
    var _reach_target := actor.get_nearest_aggro_target()
    var _reach := actor.get_attack_range()
    if _reach_target and _reach > 0.0 and actor.global_position.distance_to(_reach_target.global_position) <= _reach:
        change_state(ActorStateId.ATTACK)
        return

    # Move toward target.
    _move_timer += delta
    if _move_timer >= move_update_interval:
        _move_timer = 0.0
        var target := actor.get_nearest_aggro_target()
        if target:
            var stop_dist := actor.get_attack_range() * 0.5
            actor.move_to_position(target.global_position, chase_speed, stop_dist)
            actor.set_facing_direction(
                actor.global_position.direction_to(target.global_position),
                Actor.ANIM_MOVE,
            )
