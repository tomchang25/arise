class_name LineBeamEffect
extends AttackEffect
## Attack phase for the Line Beam delivery.
##
## Injects a RectangleShape2D into the Hitbox aligned with the delivery's
## forward (+X local) direction and renders a glowing beam VFX for its duration.
## Intended for continuous (damage_interval > 0) damage over the full lifetime.
##
## Authoring
## ─────────
## Build a scene with this script as root. Add one child:
##   • Hitbox  ($Hitbox) — leave shape blank; this script injects RectangleShape2D.
##
## EffectPhaseDefinition settings
## ──────────────────────────────
##   effect_scene        = line_beam_effect.tscn
##   lifetime            = 5.0
##   damage_interval     = 0.5   (continuous ticks while inside)
##   max_targets         = -1    (unlimited)
##   clear_records_on_exit = true (re-entering after dodge restarts damage)

@export_group("Beam Shape")
## Length of the beam rectangle (extends in local +X from the delivery origin).
@export var beam_length: float = 220.0
## Full width of the beam rectangle.
@export var beam_width: float = 28.0

@export_group("Beam VFX")
@export var beam_color: Color = Color(0.5, 0.9, 1.0, 0.9)
@export var fill_alpha: float = 0.25
@export var edge_width: float = 3.5

var _beam_fill: Polygon2D
var _beam_outline: Line2D


# ─────────────────────────────────────────────
# PhaseEffect / AttackEffect overrides
# ─────────────────────────────────────────────

func setup(ctx: EffectContext) -> void:
    super.setup(ctx)

    if hitbox and hitbox.shape == null:
        var rect := RectangleShape2D.new()
        rect.size = Vector2(beam_length, beam_width)
        # RectangleShape2D is centred at the CollisionShape2D origin by default,
        # so the hitbox naturally spans ±beam_length/2 around the delivery origin
        # (the target position), matching the telegraph rectangle.
        hitbox.shape = rect


func play(duration: float = 5.0) -> void:
    _build_beam_vfx()
    _play_beam_vfx(duration)

    await get_tree().create_timer(duration).timeout
    finished.emit()
    queue_free()


# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

func _build_beam_vfx() -> void:
    var hw := beam_width * 0.5
    var hl := beam_length * 0.5

    # Semi-transparent filled beam, centred on delivery origin (target position).
    var fill_color := beam_color
    fill_color.a = fill_alpha
    _beam_fill = Polygon2D.new()
    _beam_fill.color = fill_color
    _beam_fill.polygon = PackedVector2Array([
        Vector2(-hl, -hw),
        Vector2( hl, -hw),
        Vector2( hl,  hw),
        Vector2(-hl,  hw),
    ])
    add_child(_beam_fill)

    # Glowing edge outline.
    _beam_outline = Line2D.new()
    _beam_outline.width = edge_width
    _beam_outline.default_color = beam_color
    _beam_outline.joint_mode = Line2D.LINE_JOINT_ROUND
    _beam_outline.closed = true
    _beam_outline.add_point(Vector2(-hl, -hw))
    _beam_outline.add_point(Vector2( hl, -hw))
    _beam_outline.add_point(Vector2( hl,  hw))
    _beam_outline.add_point(Vector2(-hl,  hw))
    add_child(_beam_outline)


## Flicker the beam fill to simulate energy surging through it.
func _play_beam_vfx(duration: float) -> void:
    var tick := 0.25
    var loop_count := int(max(1.0, duration / tick))
    var tween := create_tween().set_loops(loop_count)
    tween.tween_property(_beam_fill, "modulate:a", 0.5, tick * 0.5)
    tween.tween_property(_beam_fill, "modulate:a", 1.0, tick * 0.5)
