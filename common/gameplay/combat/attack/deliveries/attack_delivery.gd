class_name AttackDelivery
extends CharacterBody2D
## Base class for all detached attack deliveries.
##
## Owns the lifetime failsafe timer and dispatches trigger() to either the
## PhaseSequencer (new path) or the legacy single-effect path, depending on
## whether ctx.phases is populated.
##
## TriggerComponent auto-wiring
## ────────────────────────────
## If the delivery scene has a TriggerComponent child node, setup() wires it
## automatically:
##   • TriggerComponent.target_factions  ← set from ctx.target_factions
##   • TriggerComponent.triggered        → trigger()
##
## arm() is NOT called automatically.  The subclass decides when the delivery
## becomes live:
##   • Call arm() immediately in setup() → live from spawn.
##   • Let TriggerComponent.arm() be called externally → dormant until then.
##
## For deliveries that use TriggerComponent, calling arm() on the delivery
## also calls arm() on the component (see arm() below).
##
## Lifetime timer behaviour
## ────────────────────────
## Timer is created paused in setup().  arm() starts it.
## Acts as a hard failsafe ceiling — the delivery is always freed on timeout
## regardless of what else is running.
##
## Legacy single-effect path
## ─────────────────────────
## ctx.phases empty → trigger() uses the original attack_effect_scene flow.
## All existing subclasses are unaffected.

var lifetime_timer: Timer

var _context: EffectContext
var _sequencer: PhaseSequencer
var _trigger_component: TriggerComponent

## If true, trigger() stops the lifetime timer and lets the effect / sequencer
## drive cleanup via queue_free.  Set by subclasses (e.g. TimebombDelivery).
var _wait_for_effect: bool = false


func setup(ctx: EffectContext) -> void:
    _context = ctx
    _init_lifetime_timer(ctx.attack_lifetime)
    _autowire_trigger_component()


## Start the lifetime failsafe timer and arm the TriggerComponent if present.
##
## Subclasses call this immediately in setup() when the delivery is live from
## spawn.  Subclasses that need a dormant pre-trigger state omit this call and
## let an external signal call arm() later.
func arm() -> void:
    if lifetime_timer and lifetime_timer.is_stopped():
        lifetime_timer.start()
    if _trigger_component:
        _trigger_component.arm()


func _init_lifetime_timer(duration: float) -> void:
    lifetime_timer = Timer.new()
    lifetime_timer.one_shot = true
    lifetime_timer.wait_time = max(duration, 0.01)
    lifetime_timer.connect("timeout", _on_timeout)
    add_child(lifetime_timer)
    # NOT started here — the subclass calls arm() when ready.


func _autowire_trigger_component() -> void:
    _trigger_component = find_child("TriggerComponent", true, false) as TriggerComponent
    if _trigger_component == null:
        return

    # Pass the resolved target factions so the component can set its collision mask.
    _trigger_component.target_factions = _context.target_factions

    # Wire the trigger signal to this delivery's trigger() method.
    if not _trigger_component.triggered.is_connected(trigger):
        _trigger_component.triggered.connect(trigger)


## Activate the attack effect.
## Dispatches to PhaseSequencer when ctx.phases is non-empty,
## otherwise falls back to the legacy single-effect path.
func trigger() -> void:
    if _context == null:
        push_error("AttackDelivery.trigger: _context is null on '%s'" % name)
        return

    if _context.phases.is_empty():
        push_error("AttackDelivery.trigger: _context.phases is empty on '%s'" % name)

    _trigger_phases()

# -------------------------
# Phase path (Step 2)
# -------------------------


func _trigger_phases() -> void:
    if _sequencer != null:
        push_warning("AttackDelivery._trigger_phases: sequencer already running on '%s'" % name)
        return

    _sequencer = PhaseSequencer.new()
    add_child(_sequencer)
    _sequencer.all_phases_finished.connect(_on_phases_finished)

    if _wait_for_effect:
        lifetime_timer.stop()

    _sequencer.start(_context.phases, _context)


func _on_phases_finished() -> void:
    NodeRegistry.release(self)

# -------------------------
# Failsafe timeout
# -------------------------


func _on_timeout() -> void:
    NodeRegistry.release(self)

# -------------------------
# Pool lifecycle
# -------------------------


func reset() -> void:
    _context = null
    _wait_for_effect = false
    _trigger_component = null
    if _sequencer != null:
        _sequencer.queue_free()
        _sequencer = null
    if lifetime_timer != null:
        lifetime_timer.queue_free()
        lifetime_timer = null


func set_enabled(value: bool) -> void:
    set_physics_process(value)
    if not value and lifetime_timer != null:
        lifetime_timer.stop()
