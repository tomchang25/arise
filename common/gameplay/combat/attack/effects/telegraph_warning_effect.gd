class_name TelegraphWarningEffect
extends VfxEffect
## Phase 0 of the telegraph AOE attack.
##
## Displays a warning circle at the target position and pulses it
## for the phase duration so players can read the incoming AOE.
## No Hitbox is needed — this phase deals no damage.
##
## Authoring
## ─────────
## Build a scene with this script as root. Add:
##   • Line2D  ($WarningCircle) — the ring outline, drawn procedurally.
##   • Optionally a Label or Sprite2D for an exclamation / icon.
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene  = telegraph_warning_effect.tscn
##   lifetime      = 1.5   (or however long the telegraph should last)
##   effect_scene on the NEXT phase carries the real Hitbox.

@export_group("Warning Circle")
## Radius of the warning ring in pixels.
@export var radius: float = 80.0
## How many line segments make up the circle.
@export var segments: int = 48
## Normal width of the ring stroke.
@export var ring_width: float = 4.0
## Color of the warning ring (alpha supported).
@export var ring_color: Color = Color(1.0, 0.2, 0.1, 0.85)

@export_group("Pulse Animation")
## How many times the ring pulses (scales up/down) during the warning.
@export var pulse_count: int = 3
## How much the ring scales up at each pulse peak (1.0 = no scale).
@export var pulse_scale: float = 1.08
## Fraction of the lifetime used for the final flash-in at the end.
@export var flash_fraction: float = 0.25

## Drawn procedurally in play(); no pre-authored Line2D needed in the scene.
var _ring: Line2D


# ─────────────────────────────────────────────
# PhaseEffect / AttackEffect overrides
# ─────────────────────────────────────────────

## setup() is called by PhaseSequencer right after instantiation.
## We skip super.setup() because there is intentionally no Hitbox here.
func setup(_ctx: EffectContext) -> void:
    pass


## play() drives the warning animation for `duration` seconds, then emits finished.
## Do NOT call super() — we emit finished ourselves at the end.
func play(duration: float = 1.5) -> void:
    _build_ring()
    await _animate_warning(duration)
    finished.emit()


# ─────────────────────────────────────────────
# Pool lifecycle
# ─────────────────────────────────────────────

func reset() -> void:
    if _ring != null:
        _ring.queue_free()
        _ring = null
    super.reset()


# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

## Build the ring Line2D programmatically so the scene file stays minimal.
func _build_ring() -> void:
    _ring = Line2D.new()
    _ring.width = ring_width
    _ring.default_color = ring_color
    _ring.joint_mode = Line2D.LINE_JOINT_ROUND
    _ring.begin_cap_mode = Line2D.LINE_CAP_ROUND
    _ring.end_cap_mode = Line2D.LINE_CAP_ROUND
    _ring.closed = true
    add_child(_ring)

    # Fill in the circle points.
    for i in range(segments):
        var angle := TAU * float(i) / float(segments)
        _ring.add_point(Vector2.from_angle(angle) * radius)


## Run the pulsing animation, then a quick flash as the burst is about to land.
func _animate_warning(duration: float) -> Tween:
    var pulse_duration := duration * (1.0 - flash_fraction)
    var flash_duration := duration * flash_fraction

    # --- Pulse phase ---
    # Scale the ring up and down `pulse_count` times over `pulse_duration`.
    var pulse_tween := create_tween().set_loops(pulse_count)
    pulse_tween.tween_property(
        _ring, "scale",
        Vector2.ONE * pulse_scale,
        pulse_duration / (pulse_count * 2.0),
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    pulse_tween.tween_property(
        _ring, "scale",
        Vector2.ONE,
        pulse_duration / (pulse_count * 2.0),
    ).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

    await get_tree().create_timer(pulse_duration).timeout
    pulse_tween.kill()
    _ring.scale = Vector2.ONE

    # --- Flash phase: rapid opacity blink to signal imminent burst ---
    var flash_tween := create_tween().set_loops(3)
    flash_tween.tween_property(
        _ring, "modulate:a",
        0.1,
        flash_duration / 6.0,
    ).set_trans(Tween.TRANS_LINEAR)
    flash_tween.tween_property(
        _ring, "modulate:a",
        1.0,
        flash_duration / 6.0,
    ).set_trans(Tween.TRANS_LINEAR)

    await flash_tween.finished
    return flash_tween
