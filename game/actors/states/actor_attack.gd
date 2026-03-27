## Shared attack state for all actors.
##
## Fires the primary weapon at the nearest reachable target, with optional slow creep.
##
## Transitions:
##   → RETURN_TO_ANCHOR  if group clears aggro
##   → CHASE             if target moves out of reach
extends ActorState

@export var animation_state: StringName = Actor.ANIM_ATTACK
@export var weapon_index: int = 0
@export var attack_index: int = 0

## Slow-creep speed while repositioning inside the attack state.
@export var attack_speed: float = 100.0

@export var move_update_interval: float = 1.0

var _move_timer: float = 0.0


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


func _update(delta: float) -> void:
    # --- Exit conditions ---

    # Group cleared aggro → return home.
    if actor.is_deaggro_active():
        change_state(ActorStateId.RETURN_TO_ANCHOR)
        return

    # --- Target validation (reach_detection is OFF, use distance instead) ---

    # get_nearest_aggro_target() works for both Enemy (group_target) and Army (aggro_detection)
    var target := actor.get_nearest_aggro_target()
    if not target:
        change_state(ActorStateId.CHASE)
        return

    var reach := actor.get_attack_range()
    if reach > 0.0 and actor.global_position.distance_to(target.global_position) > reach:
        # Target walked out of melee range → hand back to Chase
        change_state(ActorStateId.CHASE)
        return

    # --- Attack ---

    if actor.can_attack(weapon_index, attack_index):
        actor.play_animation(animation_state, 1.0, true)
        actor.perform_attack(target.global_position, weapon_index, attack_index)
        actor.set_facing_direction(
            actor.global_position.direction_to(target.global_position),
            animation_state,
        )

    # --- Slow creep: keep closing distance while attacking ---

    if reach > 0.0:
        var dist := actor.global_position.distance_to(target.global_position)
        var close_threshold := reach * 0.5 # stop zone — inside this, don't move
        var creep_threshold := reach * 0.75 # outer band — start creeping inward

        if dist <= close_threshold:
            actor.stop_movement()
        elif dist > creep_threshold:
            _move_timer += delta
            if _move_timer >= move_update_interval:
                _move_timer = 0.0
                actor.move_to_position(target.global_position, attack_speed, close_threshold)
                actor.set_facing_direction(
                    actor.global_position.direction_to(target.global_position),
                    animation_state,
                )


func _on_attack_finished() -> void:
    actor.end_attack(weapon_index, attack_index)
