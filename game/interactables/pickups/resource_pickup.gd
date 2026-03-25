class_name ResourcePickup
extends BasePickup

const MAX_ICON_SIZE := Vector2(8.0, 8.0)

@export_group("Resource")
@export var resource_data: ResourceData:
    set(value):
        resource_data = value
        _refresh_visual()

@export var amount: int = 1:
    set(value):
        amount = max(value, 1)

@export_group("Dependencies")
@export var sprite_node: Sprite2D

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    super._ready()
    _refresh_visual()

# -------------------------
# Common API
# -------------------------


func reset() -> void:
    # Clear resource-level state before restoring base pickup state.
    resource_data = null
    amount = 1
    _refresh_visual()
    super.reset()

# -------------------------
# Feature APIs
# -------------------------


func setup_resource(data: ResourceData, stack_amount: int) -> void:
    resource_data = data
    amount = max(stack_amount, 1)
    _refresh_visual()

# -------------------------
# Internal Helpers
# -------------------------


func _validate_configuration() -> bool:
    return resource_data != null and resource_data.is_valid()


func _can_collect_from(_collector: Node, pickup_collector_module: PickupCollectorModule) -> bool:
    if resource_data == null:
        return false
    if pickup_collector_module == null:
        return false

    return pickup_collector_module.can_collect_resource(resource_data, amount)


func _apply_to_collector(_collector: Node, pickup_collector_module: PickupCollectorModule) -> bool:
    if resource_data == null:
        return false
    if pickup_collector_module == null:
        return false

    return pickup_collector_module.collect_resource(resource_data, amount)


func _refresh_visual() -> void:
    if sprite_node == null:
        return

    sprite_node.texture = null
    sprite_node.scale = Vector2.ONE

    if resource_data == null:
        return

    sprite_node.texture = resource_data.sprite
    _fit_sprite_to_max_size(sprite_node, MAX_ICON_SIZE)


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
