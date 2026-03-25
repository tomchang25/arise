@tool
class_name PickupCollectorModule
extends Node2D

signal pickup_entered(pickup: BasePickup)
signal pickup_exited(pickup: BasePickup)
signal pickup_collected(pickup: BasePickup)

@export var enabled := true:
    set = set_enabled

var _enabled: bool = true

@export_group("Dependencies")
@export var owner_body: Node2D
@export var stats: Stats
@export var inventory_owner: Node

@export_group("Collection")
@export var resource_full_check_enabled := true
## Direct-collect radius in pixels. When a pickup's centre is within this
## distance of the collector the pickup is collected immediately, replacing
## the old Area2D body_entered behaviour.
@export var collect_range: float = 8.0

@export_group("Magnet")
@export var magnet_enabled := true
@export var magnet_range: float = 48.0:
    set(value):
        magnet_range = max(value, 0.0)

var _pickups_in_range: Array[BasePickup] = []

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _refresh_runtime_state()


func _physics_process(_delta: float) -> void:
    if not _enabled:
        return

    # Query SpatialHash for all pickups within the effective search radius.
    var query_radius_px := max(magnet_range, collect_range)
    var radius_cells := query_radius_px / SpatialHash.CELL_SIZE
    var nearby_nodes := SpatialHash.query_nearby_pickups(global_position, radius_cells)

    # Build the set of valid pickups actually within range this frame.
    var current_frame: Array[BasePickup] = []
    for node in nearby_nodes:
        if not (node is BasePickup) or not is_instance_valid(node):
            continue
        var pickup := node as BasePickup
        if global_position.distance_to(pickup.global_position) <= query_radius_px:
            current_frame.append(pickup)

    # Detect exits — pickups that left the range or became invalid.
    for i in range(_pickups_in_range.size() - 1, -1, -1):
        var pickup := _pickups_in_range[i]
        if pickup == null or not is_instance_valid(pickup) or not current_frame.has(pickup):
            _remove_pickup(pickup)

    # Detect enters — new pickups that entered the range.
    for pickup in current_frame:
        if not _pickups_in_range.has(pickup):
            _add_pickup(pickup)

    # Apply direct collect, magnet pull, or clear stale magnet targets.
    for pickup in _pickups_in_range:
        if pickup == null or not is_instance_valid(pickup):
            continue
        if global_position.distance_to(pickup.global_position) <= collect_range:
            pickup.try_collect(self)
        elif magnet_enabled:
            pickup.begin_magnet_pull(self)
        else:
            pickup.clear_magnet_target(self)

# -------------------------
# Common API
# -------------------------


func reset() -> void:
    _stop_runtime_state()
    _enabled = true
    _refresh_runtime_state()


func set_enabled(value: bool) -> void:
    _enabled = value
    if not _enabled:
        _stop_runtime_state()
    _refresh_runtime_state()


func is_enabled() -> bool:
    return _enabled

# -------------------------
# Pickup Query
# -------------------------


func has_pickup_in_range(pickup: BasePickup) -> bool:
    return _pickups_in_range.has(pickup)


func get_overlapping_pickups() -> Array[BasePickup]:
    var pickups: Array[BasePickup] = []
    for pickup in _pickups_in_range:
        if pickup != null and is_instance_valid(pickup):
            pickups.append(pickup)
    return pickups

# -------------------------
# Pickup Collection
# -------------------------


func can_collect_pickup(pickup: BasePickup) -> bool:
    if not _enabled:
        return false

    if pickup == null:
        return false

    if pickup is ResourcePickup:
        return can_collect_resource(pickup.resource_data, pickup.amount)

    if pickup is ItemPickup:
        return can_collect_item(pickup.item_data, pickup.amount)

    return false


func collect_pickup(pickup: BasePickup) -> bool:
    if not can_collect_pickup(pickup):
        return false

    if pickup is ResourcePickup:
        return collect_resource(pickup.resource_data, pickup.amount)

    if pickup is ItemPickup:
        return collect_item(pickup.item_data, pickup.amount)

    return false

# -------------------------
# Resource Collection
# -------------------------


func can_collect_resource(resource_data: ResourceData, amount: int = 1) -> bool:
    if not _enabled:
        return false
    if resource_data == null:
        return false
    if amount <= 0:
        return false
    if not resource_data.is_valid():
        return false

    var total_amount := resource_data.amount_per_unit * amount

    match resource_data.kind:
        ResourceData.ResourceKind.HEALTH:
            return can_recover_health(total_amount)
        ResourceData.ResourceKind.MANA:
            return can_add_mana(total_amount)
        ResourceData.ResourceKind.SOUL:
            return can_add_souls(int(total_amount))
        ResourceData.ResourceKind.GOLD:
            return can_add_gold(int(total_amount))

    return false


func collect_resource(resource_data: ResourceData, amount: int = 1) -> bool:
    if not can_collect_resource(resource_data, amount):
        return false

    var total_amount := resource_data.amount_per_unit * amount

    match resource_data.kind:
        ResourceData.ResourceKind.HEALTH:
            return recover_health(total_amount)
        ResourceData.ResourceKind.MANA:
            return add_mana(total_amount)
        ResourceData.ResourceKind.SOUL:
            return add_souls(int(total_amount))
        ResourceData.ResourceKind.GOLD:
            return add_gold(int(total_amount))

    return false


func can_recover_health(amount: float) -> bool:
    if amount <= 0.0:
        return false
    if stats == null:
        return false

    if not resource_full_check_enabled:
        return true

    return stats.can_recover_health(amount)


func recover_health(amount: float) -> bool:
    if stats == null:
        return false

    if not resource_full_check_enabled and amount > 0.0:
        stats.health = min(stats.health + amount, stats.current_max_health)
        return true

    return stats.recover_health(amount)


func can_add_mana(amount: float) -> bool:
    if amount <= 0.0:
        return false
    if stats == null:
        return false

    if not resource_full_check_enabled:
        return true

    return stats.can_add_mana(amount)


func add_mana(amount: float) -> bool:
    if stats == null:
        return false

    if not resource_full_check_enabled and amount > 0.0:
        stats.mana = min(stats.mana + amount, stats.current_max_mana)
        return true

    return stats.add_mana(amount)


func can_add_souls(amount: int) -> bool:
    if amount <= 0:
        return false
    if stats == null:
        return false

    return stats.can_add_souls(amount)


func add_souls(amount: int) -> bool:
    if stats == null:
        return false

    return stats.add_souls(amount)


func can_add_gold(amount: int) -> bool:
    if amount <= 0:
        return false
    if stats == null:
        return false

    return stats.can_add_gold(amount)


func add_gold(amount: int) -> bool:
    if stats == null:
        return false

    return stats.add_gold(amount)

# -------------------------
# Item Collection
# -------------------------


func can_collect_item(item_data: ItemData, amount: int = 1) -> bool:
    if not _enabled:
        return false
    if item_data == null:
        return false
    if amount <= 0:
        return false
    if inventory_owner == null:
        return false

    if inventory_owner.has_method("can_add_item"):
        return inventory_owner.can_add_item(item_data, amount)

    return inventory_owner.has_method("add_item")


func collect_item(item_data: ItemData, amount: int = 1) -> bool:
    if not can_collect_item(item_data, amount):
        return false
    if not inventory_owner.has_method("add_item"):
        return false

    inventory_owner.add_item(item_data, amount)
    return true

# -------------------------
# Internal Helpers
# -------------------------


func _refresh_runtime_state() -> void:
    set_physics_process(_enabled)


func _add_pickup(pickup: BasePickup) -> void:
    if pickup == null:
        return
    if _pickups_in_range.has(pickup):
        return

    _pickups_in_range.append(pickup)
    pickup_entered.emit(pickup)


func _remove_pickup(pickup: BasePickup) -> void:
    if pickup == null:
        return
    if not _pickups_in_range.has(pickup):
        return

    _pickups_in_range.erase(pickup)
    if is_instance_valid(pickup):
        pickup.clear_magnet_target(self)
    pickup_exited.emit(pickup)


func _stop_runtime_state() -> void:
    for pickup in _pickups_in_range:
        if pickup != null and is_instance_valid(pickup):
            pickup.clear_magnet_target(self)

    _pickups_in_range.clear()
    set_physics_process(false)
