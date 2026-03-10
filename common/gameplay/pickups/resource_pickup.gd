class_name ResourcePickup
extends BasePickup

@export_group("Resource")
@export var resource_type: StringName = &"souls":
    set(value):
        resource_type = value
        _refresh_visual()

@export var amount: int = 1:
    set(value):
        amount = max(1, value)
        _refresh_visual()

@export_group("Visual")
@export var body: Polygon2D
@export var amount_label: Label
@export var collision_shape: CollisionShape2D
@export var base_size: float = 12.0

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    super._ready()
    _refresh_visual()


# -------------------------
# Pickup Setup
# -------------------------


func setup_from_drop_result(result: LootDropResult) -> void:
    if result == null:
        return

    resource_type = result.resource_type
    amount = result.amount
    _refresh_visual()


# -------------------------
# Internal Helpers
# -------------------------


func _apply_to_collector(collector: Node) -> bool:
    match resource_type:
        &"souls":
            if collector.has_method("add_souls"):
                collector.add_souls(amount)
                return true

        &"health":
            if collector.has_method("heal"):
                collector.heal(amount)
                return true

        &"mana":
            if collector.has_method("add_mana"):
                collector.add_mana(amount)
                return true

        &"gold":
            if collector.has_method("add_gold"):
                collector.add_gold(amount)
                return true

    return false


func _refresh_visual() -> void:
    if body == null:
        return

    var radius: float = base_size + min(amount - 1, 6) * 1.5

    match resource_type:
        &"souls":
            body.color = Color(0.3, 0.9, 1.0, 1.0)
            body.polygon = _build_circle_polygon(radius, 12)
            _set_circle_collision(radius)

        &"health":
            body.color = Color(1.0, 0.25, 0.25, 1.0)
            body.polygon = PackedVector2Array(
                [
                    Vector2(0, -radius),
                    Vector2(radius, 0),
                    Vector2(0, radius),
                    Vector2(-radius, 0),
                ]
            )
            _set_circle_collision(radius)

        &"mana":
            body.color = Color(0.35, 0.55, 1.0, 1.0)
            body.polygon = _build_circle_polygon(radius, 6)
            _set_circle_collision(radius)

        &"gold":
            body.color = Color(1.0, 0.85, 0.2, 1.0)
            body.polygon = PackedVector2Array(
                [
                    Vector2(-radius, -radius),
                    Vector2(radius, -radius),
                    Vector2(radius, radius),
                    Vector2(-radius, radius),
                ]
            )
            _set_circle_collision(radius)

        _:
            body.color = Color(0.8, 0.8, 0.8, 1.0)
            body.polygon = _build_circle_polygon(radius, 8)
            _set_circle_collision(radius)

    if amount_label:
        amount_label.text = str(amount)


func _build_circle_polygon(radius: float, points: int) -> PackedVector2Array:
    var polygon := PackedVector2Array()

    for i in range(points):
        var angle := TAU * float(i) / float(points)
        polygon.append(Vector2.RIGHT.rotated(angle) * radius)

    return polygon


func _set_circle_collision(radius: float) -> void:
    if collision_shape == null:
        return

    var shape := collision_shape.shape as CircleShape2D
    if shape == null:
        shape = CircleShape2D.new()
        collision_shape.shape = shape

    shape.radius = radius
