class_name ItemPickup
extends BasePickup

const MAX_ICON_SIZE := Vector2(16.0, 16.0)
const DEFAULT_COLLISION_RADIUS := 8.0

@export_group("Item")
@export var item_data: ItemData:
    set(value):
        item_data = value
        _refresh_visual()

@export var amount: int = 1:
    set(value):
        amount = max(value, 1)
        _refresh_label()

@export_group("Dependencies")
@export var sprite_node: Sprite2D
@export var label_node: Label
@export var collision_shape: CollisionShape2D

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    super._ready()
    _refresh_visual()


# -------------------------
# Feature APIs
# -------------------------


func setup_item(data: ItemData, stack_amount: int) -> void:
    item_data = data
    amount = max(stack_amount, 1)
    _refresh_visual()


# -------------------------
# Internal Helpers
# -------------------------


func _validate_configuration() -> bool:
    return item_data != null and item_data.is_valid()


func _can_collect_from(_collector: Node, pickup_collector_module: PickupCollectorModule) -> bool:
    if item_data == null:
        return false
    if pickup_collector_module == null:
        return false

    return pickup_collector_module.can_collect_item(item_data, amount)


func _apply_to_collector(_collector: Node, pickup_collector_module: PickupCollectorModule) -> bool:
    if item_data == null:
        return false
    if pickup_collector_module == null:
        return false

    return pickup_collector_module.collect_item(item_data, amount)


func _refresh_visual() -> void:
    _refresh_sprite()
    _refresh_label()
    _refresh_collision()


func _refresh_sprite() -> void:
    if sprite_node == null:
        return

    sprite_node.texture = null
    sprite_node.scale = Vector2.ONE

    if item_data == null:
        return

    sprite_node.texture = item_data.sprite
    _fit_sprite_to_max_size(sprite_node, MAX_ICON_SIZE)


func _refresh_label() -> void:
    if label_node == null:
        return

    if item_data == null:
        label_node.text = ""
        return

    if amount > 1:
        label_node.text = "%s x%d" % [item_data.label, amount]
    else:
        label_node.text = item_data.label


func _refresh_collision() -> void:
    if collision_shape != null and collision_shape.shape is CircleShape2D:
        var circle_shape := collision_shape.shape as CircleShape2D
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
