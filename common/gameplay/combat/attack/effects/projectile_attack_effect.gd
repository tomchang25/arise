class_name ProjectileAttackEffect
extends AttackEffect

## Visual presentation for a projectile attack.
##
## Draws a comet-shaped Line2D and injects a CircleShape2D into the Hitbox.
## No motion or lifetime logic — those are owned by ProjectileAttackDelivery.
## play() is called by AttackDelivery with the delivery lifetime as duration.

@export_group("Projectile Visuals")
@export var projectile_length: float = 40.0
@export var projectile_width: float = 6.0

@onready var line_2d: Line2D = $Line2D


func setup(data: AttackData) -> void:
    super.setup(data)

    if hitbox:
        _generate_projectile_shape()


## Called by AttackDelivery with the delivery lifetime as duration.
func play(duration: float) -> void:
    _play_projectile_vfx(duration)


# -------------------------
# Internal helpers
# -------------------------


func _generate_projectile_shape() -> void:
    if hitbox.shape != null:
        return

    var circle := CircleShape2D.new()
    circle.radius = projectile_width / 2.0
    hitbox.shape = circle


func _play_projectile_vfx(duration: float) -> void:
    line_2d.clear_points()
    line_2d.width = projectile_width
    line_2d.add_point(Vector2.ZERO)
    line_2d.add_point(Vector2(-projectile_length, 0.0))

    var tween := create_tween().set_loops()
    tween.tween_property(line_2d, "width", projectile_width * 1.2, duration * 0.1)
    tween.tween_property(line_2d, "width", projectile_width, duration * 0.1)
