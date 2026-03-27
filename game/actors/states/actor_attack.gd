## Shared attack state for all actors.
##
## Fires the primary weapon at the nearest reachable target, with optional slow creep.
## Supports a three-phase animation sequence driven by AttackDefinition fields:
##
##   1. Prepare  — plays prepare_animation while the telegraph phase runs.
##                 Duration is read from def.phases[prepare_phase_index].lifetime
##                 so the actor animation stays in sync with the delivery timer.
##   2. Cast     — plays cast_animation (if set) after the prepare timer expires.
##                 Intended for channeled attacks that loop until attack_finished.
##   3. Default  — plays animation_state directly when prepare_animation is empty.
##
## When locks_movement is true on the definition, the actor is frozen for the
## full duration (prepare + cast) and unlocked on attack_finished or state exit.
##
## Transitions:
##   → RETURN_TO_ANCHOR  if group clears aggro
##   → CHASE             if target moves out of reach
extends ActorState

@export var animation_state: StringName = Actor.ANIM_ATTACK
@export var weapon_index: int = 0
@export var attack_index: int = 0

## Slow-creep speed while repositioning inside the attack state.
@export var attack_speed: float = 30.0

@export var move_update_interval: float = 0.1

# -------------------------
# Runtime state
# -------------------------

var _move_timer: float = 0.0

## True while the actor is locked in place due to locks_movement on the definition.
var _movement_locked: bool = false

## The definition of the attack that is currently in flight.
## Set when perform_attack fires, cleared on attack_finished or exit.
var _current_def: AttackDefinition = null

## Timer reference for the prepare → cast/attack animation transition.
## Disconnected and cleared in _exit() if the state is interrupted mid-prepare.
var _prepare_timer: SceneTreeTimer = null

## True while a prepare or cast phase is in progress.
## Exit conditions (deaggro, target lost, out of reach) are suppressed until
## attack_finished fires, so the attack always runs to completion.
var _is_attacking: bool = false


func _init() -> void:
    state_id = ActorStateId.ATTACK


func _enter() -> void:
    _move_timer = 0.0
    _movement_locked = false
    _current_def = null
    _prepare_timer = null
    _is_attacking = false

    actor.play_animation(animation_state)

    if not actor.attack_finished.is_connected(_on_attack_finished):
        actor.attack_finished.connect(_on_attack_finished)


func _exit() -> void:
    actor.end_attack(weapon_index, attack_index)
    _unlock_movement()
    _cancel_prepare_timer()

    _current_def = null
    _is_attacking = false

    if actor.attack_finished.is_connected(_on_attack_finished):
        actor.attack_finished.disconnect(_on_attack_finished)


func _update(delta: float) -> void:
    var target := actor.get_nearest_aggro_target()
    var reach := actor.get_attack_range()

    # --- Exit conditions ---
    # Suppressed while an attack is in flight (prepare or cast phase active).
    # The attack always runs to completion — attack_finished clears _is_attacking.

    if not _is_attacking:
        if actor.is_deaggro_active():
            change_state(ActorStateId.RETURN_TO_ANCHOR)
            return

        if not target:
            change_state(ActorStateId.CHASE)
            return

        if reach > 0.0 and actor.global_position.distance_to(target.global_position) > reach:
            # Target walked out of melee range → hand back to Chase.
            change_state(ActorStateId.CHASE)
            return

    # --- Attack ---

    if not _is_attacking and actor.can_attack(weapon_index, attack_index):
        _current_def = actor.get_attack_def(weapon_index, attack_index)
        _is_attacking = true

        if target:
            actor.set_facing_direction(
                actor.global_position.direction_to(target.global_position),
                animation_state,
            )
            actor.perform_attack(target.global_position, weapon_index, attack_index)

        if _current_def != null and _current_def.locks_movement:
            _lock_movement()

        _start_attack_animation()

    # --- Slow creep: keep closing distance while attacking ---
    # Skipped entirely when the actor is locked in place or mid-attack.

    if not _movement_locked and not _is_attacking and reach > 0.0 and target != null:
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
            actor.set_facing_direction(
                actor.global_position.direction_to(target.global_position),
                animation_state,
            )
            actor.perform_attack(target.global_position, weapon_index, attack_index)

        if _current_def != null and _current_def.locks_movement:
            _lock_movement()

        _start_attack_animation()

    # --- Slow creep: keep closing distance while attacking ---
    # Skipped entirely when the actor is locked in place or mid-attack.

    if not _movement_locked and not _is_attacking and reach > 0.0 and target != null:
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

# -------------------------
# Animation sequencing
# -------------------------


## Starts the correct animation immediately after perform_attack().
## If the definition has a prepare_animation, plays it and starts the prepare
## timer so the actor transitions to cast/attack when the telegraph phase ends.
## Otherwise plays animation_state directly (standard attack loop).
func _start_attack_animation() -> void:
    if _current_def == null or _current_def.prepare_animation == &"":
        # No telegraph — play attack animation immediately.
        actor.play_animation(animation_state, 1.0, true)
        return

    # Telegraph attack — play the prepare animation and start the phase timer.
    actor.play_animation(_current_def.prepare_animation, 1.0, true)
    _start_prepare_timer()


## Reads the prepare phase lifetime from the definition and starts a one-shot
## timer. When it fires, _on_prepare_ended() transitions to cast or attack anim.
func _start_prepare_timer() -> void:
    if _current_def == null:
        return

    var def := _current_def as DetachedAttackDefinition
    if def == null or def.phases.is_empty():
        # Definition has no phases to read a duration from — fall through immediately.
        _on_prepare_ended()
        return

    var phase_idx := _current_def.prepare_phase_index
    if phase_idx < 0 or phase_idx >= def.phases.size():
        push_warning(
            "ActorAttack: prepare_phase_index %d out of range for '%s' — falling through"
            % [phase_idx, def.resource_path],
        )
        _on_prepare_ended()
        return

    var duration := def.phases[phase_idx].lifetime
    _prepare_timer = get_tree().create_timer(duration)
    _prepare_timer.timeout.connect(_on_prepare_ended, CONNECT_ONE_SHOT)


## Called when the prepare timer expires. Transitions the actor animation to
## cast_animation (if set) or the default attack animation.
func _on_prepare_ended() -> void:
    _prepare_timer = null

    if _current_def == null:
        return

    if _current_def.cast_animation != &"":
        # Channeled attack — hold the cast pose until attack_finished fires.
        actor.play_animation(_current_def.cast_animation, 1.0, true)
    else:
        # Telegraph only — transition to the standard attack animation.
        actor.play_animation(animation_state, 1.0, true)


## Disconnects and drops the prepare timer reference without waiting for it to fire.
## Called from _exit() when the state is interrupted mid-prepare.
func _cancel_prepare_timer() -> void:
    if _prepare_timer == null:
        return

    if _prepare_timer.timeout.is_connected(_on_prepare_ended):
        _prepare_timer.timeout.disconnect(_on_prepare_ended)

    _prepare_timer = null

# -------------------------
# Movement lock
# -------------------------


func _lock_movement() -> void:
    if _movement_locked:
        return
    _movement_locked = true
    actor.stop_movement()
    actor.navigation_module.set_enabled(false)


func _unlock_movement() -> void:
    if not _movement_locked:
        return
    _movement_locked = false
    actor.navigation_module.set_enabled(true)

# -------------------------
# Callbacks
# -------------------------


func _on_attack_finished() -> void:
    actor.end_attack(weapon_index, attack_index)
    _unlock_movement()
    _cancel_prepare_timer()
    _current_def = null
    _is_attacking = false
    # Return to the idle attack loop so the cooldown visually settles.
    actor.play_animation(animation_state)
