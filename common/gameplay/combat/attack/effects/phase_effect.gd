class_name PhaseEffect
extends Node2D
## Base class for all phase-level effects inside an AttackDelivery.
##
## PhaseSequencer works exclusively with PhaseEffect — it calls setup(), play(),
## and awaits finished without knowing which concrete subclass it received.
##
## Two concrete branches derive from this class:
##
##   AttackEffect   — hosts a Hitbox to deal damage to enemies. This is the
##                    existing branch; all existing AttackEffect subclasses are
##                    unaffected by this refactor.
##
##   DeliveryEmitter — fires one or more independent AttackDeliveries (e.g.
##                    dropping mines from a moving arrow, or bursting bullets
##                    from a mine). Child deliveries are parented into the world
##                    tree and own their own lifetime — the emitter never tracks
##                    them after spawning.
##
## Authoring
## ─────────
## Build a scene with a PhaseEffect subclass as the root and set it as
## effect_scene on an EffectPhaseDefinition. PhaseSequencer instantiates it,
## calls setup(ctx), calls play(lifetime), then awaits finished.
##
## Subclass contract
## ─────────────────
## • Override setup(ctx)  to read the EffectContext and configure internal state.
##   Call super.setup(ctx) only if you need the base no-op.
## • Override play(duration) to run your timed logic.
##   Do NOT call super() — emit finished.emit() yourself at the end.
## • Never call queue_free() directly; emit finished and let the caller clean up.
##   PhaseSequencer releases the effect back to the pool via NodeRegistry.release()
##   after each phase's finished signal — effects must not free themselves.

## Emitted when this phase has completed its work.
## PhaseSequencer awaits this signal before advancing to the next phase.
signal finished

## Emitted when attacker_source becomes invalid and quit_on_source_invalid is true.
## PhaseSequencer listens for this to cancel remaining phases early.
signal force_quit

## When true, _process() monitors attacker_source validity and emits force_quit
## if the attacker node is freed during this phase.
## Set to true on any effect that should stop when its attacker is destroyed.
@export var quit_on_source_invalid: bool = false

## Live reference to the original attacker node. Set by PhaseSequencer after
## setup() so all effects can access the attacker for visuals or validity checks,
## without needing to plumb it through each subclass setup() override.
var attacker_source: Node2D = null


func _process(_delta: float) -> void:
    if quit_on_source_invalid:
        if not is_instance_valid(attacker_source):
            set_process(false)
            force_quit.emit()


## Called by PhaseSequencer immediately after instantiation.
## Subclasses read ctx to configure hitboxes, emitter parameters, etc.
func setup(_ctx: EffectContext) -> void:
    pass


## Called by PhaseSequencer after setup().
## Subclasses run their timed logic here and emit finished when done.
func play(_duration: float = 0.0) -> void:
    pass

# -------------------------
# Pool lifecycle
# -------------------------


## Called by NodeRegistry on re-acquire. Restores the node to a clean default
## state so setup() + play() can run again without leftover data from the
## previous use. Subclasses should call super.reset() last.
func reset() -> void:
    attacker_source = null
    set_process(false)
    visible = true


## Called by NodeRegistry on release. Disables the node so it is inert while
## cached in the pool. Subclasses should call super.set_enabled() first.
func set_enabled(value: bool) -> void:
    set_process(value)
    visible = value
