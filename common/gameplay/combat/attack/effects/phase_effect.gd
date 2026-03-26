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
var quit_on_source_invalid: bool = false

## Live reference to the original attacker node. Set by PhaseSequencer after
## setup() so all effects can access the attacker for visuals or validity checks,
## without needing to plumb it through each subclass setup() override.
var attacker_source: Node2D = null

@export_group("Attacker Line")
## When true, _build_attacker_line() draws a Line2D from attacker_source back
## to this delivery marker. The line is tracked each frame in _process() and
## freed in reset(). Call _build_attacker_line() from _build_visuals() to opt in.
@export var show_attacker_line: bool = false
@export var attacker_line_color: Color = Color(1.0, 0.45, 0.1, 0.45)
@export var attacker_line_width: float = 2.0

var _attacker_line: Line2D


func _process(_delta: float) -> void:
    if quit_on_source_invalid:
        if not is_instance_valid(attacker_source):
            set_process(false)
            force_quit.emit()
    if _attacker_line == null:
        return
    if attacker_source != null and is_instance_valid(attacker_source):
        _attacker_line.set_point_position(0, to_local(attacker_source.global_position))
    else:
        _attacker_line.visible = false


## Called by PhaseSequencer immediately after instantiation.
## Subclasses read ctx to configure hitboxes, emitter parameters, etc.
func setup(_ctx: EffectContext) -> void:
    pass


## Called by PhaseSequencer after setup().
## Subclasses run their timed logic here and emit finished when done.
func play(_duration: float = 0.0) -> void:
    pass


## Creates a Line2D connecting attacker_source back to this delivery marker.
## Call from _build_visuals() to add the attacker indicator line.
## Does nothing when show_attacker_line is false.
func _build_attacker_line() -> void:
    if not show_attacker_line:
        return
    _attacker_line = Line2D.new()
    _attacker_line.width = attacker_line_width
    _attacker_line.default_color = attacker_line_color
    _attacker_line.begin_cap_mode = Line2D.LINE_CAP_BOX
    _attacker_line.end_cap_mode = Line2D.LINE_CAP_BOX
    _attacker_line.add_point(Vector2.ZERO)  # Point 0: attacker position, updated in _process.
    _attacker_line.add_point(Vector2.ZERO)  # Point 1: this delivery marker.
    add_child(_attacker_line)
    if attacker_source != null and is_instance_valid(attacker_source):
        _attacker_line.set_point_position(0, to_local(attacker_source.global_position))

# -------------------------
# Pool lifecycle
# -------------------------


## Called by NodeRegistry on re-acquire. Restores the node to a clean default
## state so setup() + play() can run again without leftover data from the
## previous use. Subclasses should call super.reset() last.
func reset() -> void:
    attacker_source = null
    set_process(true)
    quit_on_source_invalid = false
    visible = true
    if _attacker_line != null:
        _attacker_line.queue_free()
        _attacker_line = null


## Called by NodeRegistry on release. Disables the node so it is inert while
## cached in the pool. Subclasses should call super.set_enabled() first.
func set_enabled(value: bool) -> void:
    set_process(value)
    visible = value
