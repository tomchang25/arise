class_name HeavySwingBurstEffect
extends AttackEffect
## Attack phase for the Heavy Swing delivery.
##
## Injects a sector-shaped ConvexPolygonShape2D into the Hitbox and renders an
## outward-expanding burst VFX matching the sector shape. Deals a single burst
## of damage to all enemies inside the sector (max_targets = -1, damage_interval = 0).
##
## The sector is centred at the delivery origin, oriented along the delivery's
## local +X axis (the forward / aimed direction).
##
## Authoring
## ─────────
## Build a scene with this script as root. Add one child:
##   • Hitbox  ($Hitbox) — leave shape blank; this script injects ConvexPolygonShape2D.
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene    = heavy_swing_burst_effect.tscn
##   lifetime        = 0.2
##   knockback_mode  = OUTWARD
##   knockback_force = 200.0
##   max_targets     = -1      (unlimited)
##   damage_interval = 0       (hit once on enter)

@export_group("Sector Shape")
## Must match the telegraph radius so the hitbox aligns with the warning.
@export var radius: float = 80.0
## Total arc angle in degrees. Keep ≤ 180° for a valid convex polygon.
@export var arc_angle_deg: float = 120.0
## Segments used to approximate the arc in both shape and VFX.
@export var segments: int = 20

@export_group("Burst VFX")
@export var burst_color: Color = Color(1.0, 0.6, 0.15, 1.0)
@export var edge_width: float = 5.0


# ─────────────────────────────────────────────
# PhaseEffect / AttackEffect overrides
# ─────────────────────────────────────────────

func setup(ctx: EffectContext) -> void:
    super.setup(ctx)

    if hitbox and hitbox.shape == null:
        hitbox.shape = _build_sector_shape()


func play(duration: float = 0.2) -> void:
    _play_burst_vfx(duration)

    await get_tree().create_timer(duration).timeout
    finished.emit()
    queue_free()


# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

## Builds a ConvexPolygonShape2D approximating the sector.
## Valid for arc_angle_deg ≤ 180°; Godot computes the convex hull automatically.
func _build_sector_shape() -> ConvexPolygonShape2D:
    var half_arc := deg_to_rad(arc_angle_deg * 0.5)
    var pts := PackedVector2Array()
    pts.append(Vector2.ZERO)
    for i in range(segments + 1):
        var t := float(i) / float(segments)
        var angle := lerp(-half_arc, half_arc, t)
        pts.append(Vector2.from_angle(angle) * radius)
    var shape := ConvexPolygonShape2D.new()
    shape.points = pts
    return shape


## Flashes the sector outline and expands it to signal the burst landing.
func _play_burst_vfx(duration: float) -> void:
    var half_arc := deg_to_rad(arc_angle_deg * 0.5)

    # Arc line.
    var arc_line := Line2D.new()
    arc_line.width = edge_width
    arc_line.default_color = burst_color
    arc_line.joint_mode = Line2D.LINE_JOINT_ROUND
    arc_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    arc_line.end_cap_mode = Line2D.LINE_CAP_ROUND
    for i in range(segments + 1):
        var t := float(i) / float(segments)
        var angle := lerp(-half_arc, half_arc, t)
        arc_line.add_point(Vector2.from_angle(angle) * radius)
    add_child(arc_line)

    # Two radial lines.
    for sign_val in [-1, 1]:
        var radial := Line2D.new()
        radial.width = edge_width
        radial.default_color = burst_color
        radial.add_point(Vector2.ZERO)
        radial.add_point(Vector2.from_angle(sign_val * half_arc) * radius)
        add_child(radial)

    # Expand and fade out.
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(
        self, "scale",
        Vector2(1.35, 1.35),
        duration,
    ).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
    tween.tween_property(
        self, "modulate:a",
        0.0,
        duration,
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
