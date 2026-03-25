class_name ScorchEffect
extends VfxEffect
## Phase 2 of the telegraph AOE attack — lingering scorch mark.
##
## Draws a filled scorch decal at the blast centre. No Hitbox, no damage.
## Fades out over the last 20 % of its lifetime so the mark disappears smoothly.
##
## Authoring
## ─────────
## Build a scene with this script as root. No children are required —
## the decal is drawn procedurally via a filled polygon.
## You can optionally add a CPUParticles2D child for smoke/embers.
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene = scorch_effect.tscn
##   lifetime     = 10.0
##   (all hit fields ignored — VfxOnlyEffect skips Hitbox wiring)

@export_group("Scorch Decal")
@export var radius: float = 80.0
@export var segments: int = 48
## Color of the scorch fill.
@export var scorch_color: Color = Color(0.08, 0.06, 0.05, 0.75)
## Color of the outer ring edge.
@export var edge_color: Color = Color(0.3, 0.1, 0.0, 0.6)
@export var edge_width: float = 3.0

@export_group("Fade")
## Fraction of lifetime that the fade-out occupies (e.g. 0.2 = last 20 %).
@export var fade_fraction: float = 0.2

var _fill: Polygon2D
var _edge: Line2D

# ─────────────────────────────────────────────
# PhaseEffect / AttackEffect overrides
# ─────────────────────────────────────────────


## VfxOnlyEffect.setup() zeros max_targets and skips Hitbox wiring — call super.
func setup(ctx: EffectContext) -> void:
    super.setup(ctx)


## play() renders the scorch and fades it out. Emits finished when done.
## Do NOT call super() — VfxEffect.play() does not manage our custom lifetime.
func play(duration: float = 10.0) -> void:
    _build_decal()
    await _run_lifetime(duration)
    finished.emit()


# ─────────────────────────────────────────────
# Pool lifecycle
# ─────────────────────────────────────────────

func reset() -> void:
    if _fill != null:
        _fill.queue_free()
        _fill = null
    if _edge != null:
        _edge.queue_free()
        _edge = null
    modulate = Color.WHITE
    super.reset()

# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────


func _build_decal() -> void:
    # Filled polygon.
    _fill = Polygon2D.new()
    _fill.color = scorch_color
    var pts: PackedVector2Array = []
    for i in range(segments):
        var angle := TAU * float(i) / float(segments)
        pts.append(Vector2.from_angle(angle) * radius)
    _fill.polygon = pts
    add_child(_fill)

    # Outer edge ring.
    _edge = Line2D.new()
    _edge.width = edge_width
    _edge.default_color = edge_color
    _edge.joint_mode = Line2D.LINE_JOINT_ROUND
    _edge.closed = true
    for i in range(segments):
        var angle := TAU * float(i) / float(segments)
        _edge.add_point(Vector2.from_angle(angle) * radius)
    add_child(_edge)


## Wait the active portion, then tween the alpha to zero.
func _run_lifetime(duration: float) -> void:
    var active_time := duration * (1.0 - fade_fraction)
    var fade_time := duration * fade_fraction

    await get_tree().create_timer(active_time).timeout

    # Fade the whole effect node so fill + edge fade together.
    var tween := create_tween()
    tween.tween_property(
        self,
        "modulate:a",
        0.0,
        fade_time,
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

    await tween.finished
