class_name ProjectileAttackEffect
extends AttackEffect

@export_group("Projectile Visuals")
@export var projectile_length: float = 40.0
@export var projectile_width: float = 6.0

@onready var line_2d: Line2D = $Line2D

# var velocity: Vector2 = Vector2.ZERO


func setup(info: AttackData) -> void:
    super.setup(info)

    if hitbox:
        _generate_projectile_shape()

    _play_projectile_vfx()


# func _physics_process(delta: float) -> void:
#     # Handle the "movable object" logic
#     global_position += velocity * delta


func _generate_projectile_shape() -> void:
    if hitbox.shape != null:
        return

    # Create a slender capsule for the bullet collision
    var circle = CircleShape2D.new()
    circle.radius = projectile_width / 2

    hitbox.shape = circle


func _play_projectile_vfx() -> void:
    line_2d.clear_points()
    line_2d.width = projectile_width

    # Create the comet shape points
    line_2d.add_point(Vector2.ZERO)  # Head
    line_2d.add_point(Vector2(-projectile_length, 0))  # Tail

    # Dynamic "movable" effect: Slight oscillation or scaling during flight
    var tween = create_tween().set_loops()
    tween.tween_property(line_2d, "width", projectile_width * 1.2, 0.1)
    tween.tween_property(line_2d, "width", projectile_width, 0.1)
