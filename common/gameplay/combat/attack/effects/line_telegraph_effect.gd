class_name LineTelegraphEffect
extends VfxEffect
## Telegraph phase for the Line Beam attack.
##
## Draws a rectangle warning in the delivery's forward (+X local) direction and
## a line from the attacker back to this delivery marker to indicate the source.
## No Hitbox — this phase deals no damage.
##
## Authoring
## ─────────
## Build a scene with this script as root. No children needed — all visuals are
## built procedurally in play().
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene  = line_telegraph_effect.tscn
##   lifetime      = 5.0   (telegraph duration before beam fires)
##   max_targets   = 0     (no damage)

@export_group("Beam Rectangle")
## How far the beam rectangle extends in the delivery's forward (+X) direction.
@export var beam_length: float = 220.0
## Half-width of the beam rectangle (total width = beam_width).
@export var beam_width: float = 28.0

@export_group("Warning VFX")
@export var ring_color: Color = Color(1.0, 0.85, 0.1, 0.9)
@export var ring_width: float = 3.0
@export var pulse_count: int = 3
@export var pulse_scale: float = 1.06
## Fraction of the lifetime used for the final flash-in at the end.
@export var flash_fraction: float = 0.2

var _rect_outline: Line2D

# ─────────────────────────────────────────────
# PhaseEffect overrides
# ─────────────────────────────────────────────


func play(duration: float = 5.0) -> void:
    _build_visuals()
    await _animate(duration)
    finished.emit()

# ─────────────────────────────────────────────
# Pool lifecycle
# ─────────────────────────────────────────────


func reset() -> void:
    if _rect_outline != null:
        _rect_outline.queue_free()
        _rect_outline = null
    super.reset()

# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────


func _build_visuals() -> void:
    var hw := beam_width * 0.5
    var hl := beam_length * 0.5

    # Rectangle outline centred on the delivery origin (target position).
    # Extends ±hl in the delivery's forward (+X) direction.
    _rect_outline = Line2D.new()
    _rect_outline.width = ring_width
    _rect_outline.default_color = ring_color
    _rect_outline.joint_mode = Line2D.LINE_JOINT_ROUND
    _rect_outline.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _rect_outline.end_cap_mode = Line2D.LINE_CAP_ROUND
    _rect_outline.closed = true
    _rect_outline.add_point(Vector2(-hl, -hw))
    _rect_outline.add_point(Vector2(hl, -hw))
    _rect_outline.add_point(Vector2(hl, hw))
    _rect_outline.add_point(Vector2(-hl, hw))
    add_child(_rect_outline)

    show_attacker_line = true
    attacker_line_color = Color(1.0, 0.85, 0.1, 0.45)
    _build_attacker_line()


func _animate(duration: float) -> void:
    var pulse_dur := duration * (1.0 - flash_fraction)
    var flash_dur := duration * flash_fraction

    # Pulse the rectangle outline.
    var pulse_tween := create_tween().set_loops(pulse_count)
    pulse_tween.tween_property(
        _rect_outline,
        "scale",
        Vector2.ONE * pulse_scale,
        pulse_dur / (pulse_count * 2.0),
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    pulse_tween.tween_property(
        _rect_outline,
        "scale",
        Vector2.ONE,
        pulse_dur / (pulse_count * 2.0),
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    await get_tree().create_timer(pulse_dur).timeout
    pulse_tween.kill()
    _rect_outline.scale = Vector2.ONE

    # Final flash: rapid opacity blink to signal imminent beam.
    var flash_tween := create_tween().set_loops(3)
    flash_tween.tween_property(
        _rect_outline,
        "modulate:a",
        0.1,
        flash_dur / 6.0,
    ).set_trans(Tween.TRANS_LINEAR)
    flash_tween.tween_property(
        _rect_outline,
        "modulate:a",
        1.0,
        flash_dur / 6.0,
    ).set_trans(Tween.TRANS_LINEAR)

    await flash_tween.finished
