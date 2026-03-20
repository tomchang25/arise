class_name AoeBurstEffect
extends AttackEffect
## Phase 1 of the telegraph AOE attack — the actual damage burst.
##
## Injects a CircleShape2D into the Hitbox, flashes an expansion ring VFX,
## and exits after `duration` (0.2 s by default). Hits all enemies inside
## the radius once (damage_interval = 0, max_targets = -1 unlimited).
##
## Authoring
## ─────────
## Build a scene with this script as root. Add a single child:
##   • Hitbox  ($Hitbox) — leave shape blank; this script sets CircleShape2D.
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene    = aoe_burst_effect.tscn
##   lifetime        = 0.2
##   knockback_mode  = OUTWARD
##   knockback_force = 200.0   (or your desired value)
##   max_targets     = -1      (unlimited)
##   damage_interval = 0       (hit once on enter)

@export_group("AOE Burst")
## Must match the warning circle radius so the damage aligns with the telegraph.
@export var radius: float = 80.0
@export var segments: int = 48

@export_group("Burst VFX")
@export var ring_color: Color = Color(1.0, 0.5, 0.1, 1.0)
@export var ring_width: float = 6.0

var _ring: Line2D


# ─────────────────────────────────────────────
# PhaseEffect / AttackEffect overrides
# ─────────────────────────────────────────────

func setup(ctx: EffectContext) -> void:
    # Wire the Hitbox through the base class (finds first Hitbox child).
    super.setup(ctx)

    # Inject the circle collision shape if the Hitbox has none yet.
    if hitbox and hitbox.shape == null:
        var circle := CircleShape2D.new()
        circle.radius = radius
        hitbox.shape = circle


func play(duration: float = 0.2) -> void:
    _build_ring()
    _play_burst_vfx(duration)

    await get_tree().create_timer(duration).timeout
    finished.emit()
    # Note: AttackEffect.play() calls queue_free after finished — we mirror that here.
    queue_free()


# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

func _build_ring() -> void:
    _ring = Line2D.new()
    _ring.width = ring_width
    _ring.default_color = ring_color
    _ring.joint_mode = Line2D.LINE_JOINT_ROUND
    _ring.closed = true

    for i in range(segments):
        var angle := TAU * float(i) / float(segments)
        _ring.add_point(Vector2.from_angle(angle) * radius)

    # Start small and expand outward.
    _ring.scale = Vector2(0.2, 0.2)
    add_child(_ring)


## Tween the ring outward from 20 % to 120 % scale while fading out.
func _play_burst_vfx(duration: float) -> void:
    var tween := create_tween()
    tween.set_parallel(true)

    tween.tween_property(
        _ring, "scale",
        Vector2(1.2, 1.2),
        duration,
    ).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

    tween.tween_property(
        _ring, "modulate:a",
        0.0,
        duration,
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
