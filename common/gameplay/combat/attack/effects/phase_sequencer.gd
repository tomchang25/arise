class_name PhaseSequencer
extends Node
## Drives an ordered array of EffectPhaseDefinitions inside an AttackDelivery.
##
## Owned and added as a child by AttackDelivery when trigger() is called.
## Each phase runs to completion (effect.finished signal) before the next starts.
## Emits all_phases_finished when the array is exhausted; AttackDelivery connects
## queue_free to that signal so cleanup is always sequencer-driven.
##
## VFX-only phases (effect_scene == null) are handled inline — the sequencer
## waits the phase lifetime via a SceneTree timer and advances without spawning
## any PhaseEffect node.
##
## Phase-specific overrides (damage_interval, max_targets, clear_records_on_exit)
## are applied by building a per-phase EffectContext fork through
## EffectContext.build_phase_override(). The parent context is never mutated.
##
## PhaseEffect polymorphism
## ────────────────────────
## The sequencer works with PhaseEffect — the shared base of AttackEffect and
## DeliveryEmitter. It calls setup(), play(), and awaits finished without
## knowing which concrete type was instantiated. The effect_scene on each
## EffectPhaseDefinition determines the concrete type at authoring time.

signal all_phases_finished

var _phases: Array[EffectPhaseDefinition] = []
var _parent_ctx: EffectContext
var _current_index: int = 0

## Set to true while a phase is running to guard against re-entrant calls.
var _running: bool = false

## Set by _on_force_quit() when an active PhaseEffect signals force_quit.
## Checked after each effect.finished await to stop the sequence early.
var _force_quit: bool = false

# -------------------------
# Public API
# -------------------------


## Begin sequencing. Call once from AttackDelivery.trigger().
## phases     — ordered array from the AttackDefinition
## parent_ctx — the EffectContext built at fire time (not mutated)
func start(phases: Array[EffectPhaseDefinition], parent_ctx: EffectContext) -> void:
    if _running:
        push_warning("PhaseSequencer: start() called while already running — ignoring")
        return

    if phases.is_empty():
        push_error("PhaseSequencer: phases array is empty — nothing to run")
        all_phases_finished.emit()
        return

    if parent_ctx == null:
        push_error("PhaseSequencer: parent_ctx is null")
        all_phases_finished.emit()
        return

    _phases = phases
    _parent_ctx = parent_ctx
    _current_index = 0
    _running = true
    _force_quit = false
    _run_next_phase()

# -------------------------
# Internal
# -------------------------


func _run_next_phase() -> void:
    if _current_index >= _phases.size():
        _running = false
        all_phases_finished.emit()
        return

    var phase_def: EffectPhaseDefinition = _phases[_current_index]
    _current_index += 1

    if phase_def == null:
        push_warning(
            "PhaseSequencer: null EffectPhaseDefinition at index %d — skipping" \
            % (_current_index - 1),
        )
        _run_next_phase()
        return

    if phase_def.lifetime <= 0.0:
        push_warning(
            "PhaseSequencer: phase %d has lifetime <= 0 — skipping" \
            % (_current_index - 1),
        )
        _run_next_phase()
        return

    # VFX-only phase — no effect scene, just wait and advance.
    if phase_def.effect_scene == null:
        await get_tree().create_timer(phase_def.lifetime).timeout
        _run_next_phase()
        return

    # Instantiate the phase effect. The root node must extend PhaseEffect —
    # either an AttackEffect (hitbox branch) or a DeliveryEmitter (spawn branch).
    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(get_parent(), 0, null, { })

    var spawn_action := SpawnPackedSceneAction.create(phase_def.effect_scene)
    spawn_action.use_pool = true

    var effect := SpawnExecutor.execute_at_node(spawn_action, get_parent() as Node2D, spawn_ctx) as PhaseEffect

    if effect == null:
        push_error(
            "PhaseSequencer: effect_scene at index %d did not instantiate to PhaseEffect" \
            % (_current_index - 1),
        )
        _run_next_phase()
        return

    if not is_instance_valid(_parent_ctx.attacker_source):
        all_phases_finished.emit()
        return

    # Build a per-phase context fork so phase overrides don't bleed into other phases.
    var phase_ctx := _parent_ctx.build_phase_override(phase_def)
    effect.setup(phase_ctx)

    # Forward the attacker source so effects can draw direction lines and monitor
    # attacker validity via quit_on_source_invalid.
    effect.attacker_source = phase_ctx.attacker_source

    # Wire force_quit to unblock the await below and stop remaining phases.
    effect.force_quit.connect(
        func():
            _force_quit = true
            if is_instance_valid(effect):
                effect.finished.emit(),
        CONNECT_ONE_SHOT,
    )

    effect.play(phase_def.lifetime)

    # Wait for the effect to signal it is done, then advance.
    await effect.finished

    # Return the effect to the pool before advancing (or stopping).
    NodeRegistry.release(effect)

    # If the effect requested early quit, cancel remaining phases.
    if _force_quit:
        _running = false
        all_phases_finished.emit()
        return

    _run_next_phase()
