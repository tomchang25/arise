## Shared chase state for all actors.
##
## Moves toward the nearest detected target. Exit when the group clears aggro.
##
## Transitions:
##   → RETURN_TO_ANCHOR  if deaggro'd or no target (group-driven)
##   → ATTACK            if target enters reach zone
extends ActorState

@export var chase_speed: float = 100.0
@export var move_update_interval: float = 1.0

var _move_timer: float = 0.0


func _init() -> void:
    state_id = ActorStateId.CHASE


func _enter() -> void:
    actor.play_animation(Actor.ANIM_MOVE, 1.5)


func _update(delta: float) -> void:
    # Group cleared aggro → return home.
    if actor.is_deaggro_active():
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # Target within reach → attack.
    if actor.is_target_in_reach():
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
