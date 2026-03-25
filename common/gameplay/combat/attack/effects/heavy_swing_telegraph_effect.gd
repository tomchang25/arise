class_name HeavySwingTelegraphEffect
extends VfxEffect
## Telegraph phase for the Heavy Swing attack.
##
## Draws a sector (arc + two radial lines) warning centred at the delivery
## origin, and a line from the attacker back to this marker to indicate who
## is about to swing. No Hitbox — this phase deals no damage.
##
## The delivery is placed at the target position and the sector is centred
## there, representing the area the swing will cover.
##
## Authoring
## ─────────
## Build a scene with this script as root. No children needed — all visuals
## are built procedurally in play().
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene  = heavy_swing_telegraph_effect.tscn
##   lifetime      = 5.0   (telegraph duration before burst)
##   max_targets   = 0     (no damage)

@export_group("Sector Shape")
## Radius of the swing arc.
@export var radius: float = 80.0
## Total arc angle in degrees. Keep ≤ 180° for convex hitbox compatibility.
@export var arc_angle_deg: float = 120.0
## Number of line segments approximating the arc.
@export var segments: int = 20

@export_group("Warning VFX")
@export var ring_color: Color = Color(1.0, 0.45, 0.1, 0.9)
@export var ring_width: float = 3.0
@export var pulse_count: int = 3
@export var pulse_scale: float = 1.06
## Fraction of the lifetime used for the final flash-in at the end.
@export var flash_fraction: float = 0.2

@export_group("Attacker Line")
@export var source_line_color: Color = Color(1.0, 0.45, 0.1, 0.45)
@export var source_line_width: float = 2.0

var _arc_line: Line2D
var _radial_a: Line2D
var _radial_b: Line2D
var _sector_root: Node2D # Parent of the three sector lines for batch animation.
var _source_line: Line2D

# ─────────────────────────────────────────────
# PhaseEffect overrides
# ─────────────────────────────────────────────


func _process(_delta: float) -> void:
    super._process(_delta)
    if _source_line == null:
        return

    if attacker_source != null and is_instance_valid(attacker_source):
        _source_line.set_point_position(0, to_local(attacker_source.global_position))
    else:
        _source_line.visible = false


func play(duration: float = 5.0) -> void:
    _build_visuals()
    await _animate(duration)
    finished.emit()

# ─────────────────────────────────────────────
# Pool lifecycle
# ─────────────────────────────────────────────


func reset() -> void:
    if _sector_root != null:
        _sector_root.queue_free()
        _sector_root = null
        _arc_line = null
        _radial_a = null
        _radial_b = null
    if _source_line != null:
        _source_line.queue_free()
        _source_line = null
    super.reset()

# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────


## Returns the offset that shifts sector geometry so its centroid lands at origin.
## Sector centroid is at (2r·sin(α))/(3α) from the apex along the bisector.
func _sector_centroid_offset() -> Vector2:
    var half_arc := deg_to_rad(arc_angle_deg * 0.5)
    if half_arc < 0.0001:
        return Vector2.ZERO
    return Vector2(-(2.0 * radius * sin(half_arc)) / (3.0 * half_arc), 0.0)


func _build_visuals() -> void:
    var half_arc := deg_to_rad(arc_angle_deg * 0.5)
    var off := _sector_centroid_offset()

    _sector_root = Node2D.new()
    add_child(_sector_root)

    # Arc spanning from -half_arc to +half_arc, shifted so centroid is at origin.
    _arc_line = Line2D.new()
    _arc_line.width = ring_width
    _arc_line.default_color = ring_color
    _arc_line.joint_mode = Line2D.LINE_JOINT_ROUND
    _arc_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _arc_line.end_cap_mode = Line2D.LINE_CAP_ROUND
    for i in range(segments + 1):
        var t := float(i) / float(segments)
        var angle := lerp(-half_arc, half_arc, t)
        _arc_line.add_point(Vector2.from_angle(angle) * radius + off)
    _sector_root.add_child(_arc_line)

    # Radial from apex to arc start.
    _radial_a = Line2D.new()
    _radial_a.width = ring_width
    _radial_a.default_color = ring_color
    _radial_a.add_point(Vector2.ZERO + off)
    _radial_a.add_point(Vector2.from_angle(-half_arc) * radius + off)
    _sector_root.add_child(_radial_a)

    # Radial from apex to arc end.
    _radial_b = Line2D.new()
    _radial_b.width = ring_width
    _radial_b.default_color = ring_color
    _radial_b.add_point(Vector2.ZERO + off)
    _radial_b.add_point(Vector2.from_angle(half_arc) * radius + off)
    _sector_root.add_child(_radial_b)

    # Line from attacker back to this delivery marker.
    _source_line = Line2D.new()
    _source_line.width = source_line_width
    _source_line.default_color = source_line_color
    _source_line.begin_cap_mode = Line2D.LINE_CAP_BOX
    _source_line.end_cap_mode = Line2D.LINE_CAP_BOX
    _source_line.add_point(Vector2.ZERO) # Updated in _process.
    _source_line.add_point(Vector2.ZERO) # This delivery marker.
    add_child(_source_line)

    # Initialise immediately to avoid single-frame flicker.
    if attacker_source != null and is_instance_valid(attacker_source):
        _source_line.set_point_position(0, to_local(attacker_source.global_position))


func _animate(duration: float) -> void:
    var pulse_dur := duration * (1.0 - flash_fraction)
    var flash_dur := duration * flash_fraction

    # Pulse the whole sector root.
    var pulse_tween := create_tween().set_loops(pulse_count)
    pulse_tween.tween_property(
        _sector_root,
        "scale",
        Vector2.ONE * pulse_scale,
        pulse_dur / (pulse_count * 2.0),
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    pulse_tween.tween_property(
        _sector_root,
        "scale",
        Vector2.ONE,
        pulse_dur / (pulse_count * 2.0),
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    await get_tree().create_timer(pulse_dur).timeout
    pulse_tween.kill()
    _sector_root.scale = Vector2.ONE

    # Final flash before burst lands.
    var flash_tween := create_tween().set_loops(3)
    flash_tween.tween_property(
        _sector_root,
        "modulate:a",
        0.1,
        flash_dur / 6.0,
    ).set_trans(Tween.TRANS_LINEAR)
    flash_tween.tween_property(
        _sector_root,
        "modulate:a",
        1.0,
        flash_dur / 6.0,
    ).set_trans(Tween.TRANS_LINEAR)

    await flash_tween.finished
