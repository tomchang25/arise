class_name ProjectileAttackEffect
extends AttackEffect
## Visual presentation for a projectile attack.
##
## Draws a comet-shaped Line2D and injects a CircleShape2D into the Hitbox.
## No motion or lifetime logic — those are owned by ProjectileDelivery.
## play() is called by PhaseSequencer (or legacy AttackDelivery) with the
## phase lifetime as duration.

@export_group("Projectile Visuals")
@export var projectile_length: float = 40.0
@export var projectile_width: float = 6.0
@export var projectile_color: Color = Color.WHITE

@onready var line_2d: Line2D = $Line2D


func setup(ctx: EffectContext) -> void:
    super.setup(ctx)

    if hitbox:
        _generate_projectile_shape()


## Plays the projectile visual for `duration` seconds, then emits finished.
## The tween pulses the line width for the full duration, then stops cleanly.
func play(duration: float = 1.0) -> void:
    _play_projectile_vfx()
    # Base class waits duration then emits finished — drive cleanup from there.
    await get_tree().create_timer(duration).timeout
    finished.emit()

# -------------------------
# Internal helpers
# -------------------------


func _generate_projectile_shape() -> void:
    if hitbox.shape != null:
        return

    var circle := CircleShape2D.new()
    circle.radius = projectile_width / 2.0
    hitbox.shape = circle


func _play_projectile_vfx(duration: float = 1.0) -> void:
    line_2d.clear_points()
    line_2d.default_color = projectile_color
    line_2d.width = projectile_width
    line_2d.add_point(Vector2.ZERO)
    line_2d.add_point(Vector2(-projectile_length, 0.0))

    # Non-looping tween — runs once over the full duration then stops.
    var tween := create_tween().set_loops()
    tween.tween_property(line_2d, "width", projectile_width * 1.2, duration * 0.1)
    tween.tween_property(line_2d, "width", projectile_width, duration * 0.1)
