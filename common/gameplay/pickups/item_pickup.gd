class_name ItemPickup
extends BasePickup

const DEFAULT_COLOR := Color(0.75, 0.35, 1.0, 1.0)
const DEFAULT_OUTLINE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEFAULT_SIZE := 12.0

@export_group("Item")
@export var item_id: StringName = &"":
    set(value):
        item_id = value
        _refresh_visual()

@export var item_resource: Resource

@export_group("Visual")
@export var body: Polygon2D
@export var outline: Line2D
@export var icon_label: Label
@export var collision_shape: CollisionShape2D
@export var base_size: float = DEFAULT_SIZE
@export var body_color: Color = DEFAULT_COLOR:
    set(value):
        body_color = value
        _refresh_visual()

@export var outline_color: Color = DEFAULT_OUTLINE_COLOR:
    set(value):
        outline_color = value
        _refresh_visual()

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

    item_id = result.item_id

    if result.has_method("get"):
        var resource_value = result.get("item_resource")
        if resource_value != null:
            item_resource = resource_value

    _refresh_visual()


# -------------------------
# Internal Helpers
# -------------------------


func _apply_to_collector(collector: Node) -> bool:
    if collector == null:
        return false

    if item_id == StringName():
        push_warning("ItemPickup: item_id is empty")
        return false

    if collector.has_method("grant_item_reward"):
        collector.grant_item_reward(item_id, item_resource)
        return true

    return false


func _refresh_visual() -> void:
    _refresh_body()
    _refresh_outline()
    _refresh_label()
    _refresh_collision()


func _refresh_body() -> void:
    if body == null:
        return

    body.color = body_color
    body.polygon = _build_diamond_polygon(base_size)


func _refresh_outline() -> void:
    if outline == null:
        return

    var polygon := _build_diamond_polygon(base_size)
    var points := PackedVector2Array(polygon)
    if not points.is_empty():
        points.append(points[0])

    outline.default_color = outline_color
    outline.width = 2.0
    outline.closed = false
    outline.points = points


func _refresh_label() -> void:
    if icon_label == null:
        return

    icon_label.text = _build_label_text()


func _refresh_collision() -> void:
    if collision_shape == null:
        return

    var shape := collision_shape.shape as CircleShape2D
    if shape == null:
        shape = CircleShape2D.new()
        collision_shape.shape = shape

    shape.radius = base_size


func _build_label_text() -> String:
    if item_id == StringName():
        return "?"

    var text := String(item_id)
    if text.is_empty():
        return "?"

    return text.left(1).to_upper()


func _build_diamond_polygon(radius: float) -> PackedVector2Array:
    return PackedVector2Array(
        [
            Vector2(0.0, -radius),
            Vector2(radius, 0.0),
            Vector2(0.0, radius),
            Vector2(-radius, 0.0),
        ]
    )
