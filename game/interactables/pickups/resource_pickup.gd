class_name ResourcePickup
extends BasePickup

const MAX_ICON_SIZE := Vector2(16.0, 16.0)
const DEFAULT_COLLISION_RADIUS := 8.0

@export_group("Resource")
@export var resource_data: ResourceData:
    set(value):
        resource_data = value
        _refresh_visual()

@export var amount: int = 1:
    set(value):
        amount = max(1, value)

@export_group("Nodes")
@export var sprite_node: Sprite2D
@export var collision_shape: CollisionShape2D

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    super._ready()
    _refresh_visual()


# -------------------------
# Setup API
# -------------------------


func setup_resource(data: ResourceData, value: int) -> void:
    resource_data = data
    amount = max(1, value)
    _refresh_visual()


# -------------------------
# Internal Helpers
# -------------------------


func _validate_configuration() -> bool:
    return resource_data != null and resource_data.is_valid()


func _validate_receiver(collector: Node) -> bool:
    if collector == null:
        return false

    return resource_data != null


func _apply_to_collector(collector: Node) -> bool:
    if resource_data == null:
        return false

    return resource_data.execute_effect(collector, amount)


func _refresh_visual() -> void:
    if sprite_node == null:
        return

    sprite_node.texture = null
    sprite_node.scale = Vector2.ONE

    if resource_data == null:
        return

    sprite_node.texture = resource_data.sprite
    _fit_sprite_to_max_size(sprite_node, MAX_ICON_SIZE)

    if collision_shape != null:
        var circle_shape := collision_shape.shape as CircleShape2D
        if circle_shape == null:
            circle_shape = CircleShape2D.new()
            collision_shape.shape = circle_shape
        circle_shape.radius = DEFAULT_COLLISION_RADIUS


func _fit_sprite_to_max_size(target: Sprite2D, max_size: Vector2) -> void:
    if target == null:
        return

    if target.texture == null:
        target.scale = Vector2.ONE
        return

    var texture_size := target.texture.get_size()
    if texture_size.x <= 0.0 or texture_size.y <= 0.0:
        target.scale = Vector2.ONE
        return

    var scale_x: float = max_size.x / texture_size.x
    var scale_y: float = max_size.y / texture_size.y
    var final_scale: float = min(scale_x, scale_y, 1.0)

    target.scale = Vector2.ONE * final_scale
