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
##   (AttackEffect's base play() is the only exception — it calls queue_free
##    after emitting finished, which is intentional and documented there.)

## Emitted when this phase has completed its work.
## PhaseSequencer awaits this signal before advancing to the next phase.
signal finished


## Called by PhaseSequencer immediately after instantiation.
## Subclasses read ctx to configure hitboxes, emitter parameters, etc.
func setup(_ctx: EffectContext) -> void:
    pass


## Called by PhaseSequencer after setup().
## Subclasses run their timed logic here and emit finished when done.
func play(_duration: float = 0.0) -> void:
    pass
