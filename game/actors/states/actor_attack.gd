## Shared attack state for all actors.
##
## Fires the primary weapon at the nearest reachable target, with optional slow creep.
##
## Transitions:
##   → RETURN_TO_ANCHOR  if deaggro'd or anchor too far (Enemy / Army respectively)
##   → CHASE             if target moves out of reach
extends ActorState

@export var animation_state: StringName = Actor.ANIM_ATTACK
@export var weapon_index: int = 0
@export var attack_index: int = 0

## Slow-creep speed while repositioning inside the attack state.
@export var attack_speed: float = 30.0

## Threshold used by non-deaggro actors (Army) to exit when too far from anchor.
@export var follow_threshold: float = 200.0


func _init() -> void:
    state_id = ActorStateId.ATTACK


func _enter() -> void:
    actor.play_animation(animation_state)

    if not actor.attack_finished.is_connected(_on_attack_finished):
        actor.attack_finished.connect(_on_attack_finished)


func _exit() -> void:
    actor.end_attack(weapon_index, attack_index)

    if actor.attack_finished.is_connected(_on_attack_finished):
        actor.attack_finished.disconnect(_on_attack_finished)


func _update(_delta: float) -> void:
    # Deaggro check (Enemy).
    if _has_deaggro() and actor.is_deaggro_active():
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # Anchor-distance check (Army).
    if not _has_deaggro():
        if not actor.is_aggro_active() or actor.get_distance_to_anchor() > follow_threshold:
            change_state(ActorStateId.RETURN_TO_ANCHOR)
            return

    # Target moved out of reach → hand off to chase.
    if not actor.is_target_in_reach():
        change_state(ActorStateId.CHASE)
        return

    var target := actor.get_nearest_reachable_target()
    if target:
        # Slow creep: nudge toward target in the outer band.
        var reach := _get_reach_radius()
        if reach > 0.0:
            var dist := actor.global_position.distance_to(target.global_position)
            var close_threshold := reach * 0.5
            var creep_threshold := reach * 0.75
            if dist > creep_threshold:
                actor.move_to_position(target.global_position, attack_speed, close_threshold)
                actor.set_facing_direction(actor.global_position.direction_to(target.global_position), animation_state)
            elif dist <= close_threshold:
                actor.stop_movement()

        # Fire when ready.
        if actor.can_attack(weapon_index, attack_index):
            actor.play_animation(animation_state, 1.0, true)
            actor.perform_attack(target.global_position, weapon_index, attack_index)
            actor.set_facing_direction(actor.global_position.direction_to(target.global_position), animation_state)


func _on_attack_finished() -> void:
    actor.end_attack(weapon_index, attack_index)

# -------------------------
# Internal helpers
# -------------------------


func _get_reach_radius() -> float:
    if actor.reach_detection:
        return actor.reach_detection.radius
    return 0.0


func _has_deaggro() -> bool:
    var army := actor as Army
    if army and army.data:
        return army.data.has_deaggro
    var enemy := actor as Enemy
    if enemy and enemy.data:
        return enemy.data.has_deaggro
    return false
