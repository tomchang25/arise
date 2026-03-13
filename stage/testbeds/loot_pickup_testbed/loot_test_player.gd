class_name LootTestPlayer
extends CharacterBody2D

@export_group("Dependencies")
@export var pickup_collector_module: PickupCollectorModule
@export var pickup_collector_shape: CollisionShape2D
@export var stats: Stats

@export_group("Movement")
@export var move_speed: float = 180.0

@export_group("Debug State")
@export var reset_health_value: float = 50.0
@export var reset_mana_value: float = 0.0

var granted_items: Dictionary = {}

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    add_to_group("player")
    _wire_modules()
    reset_test_state()


func _physics_process(_delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

    velocity = input_dir * move_speed
    move_and_slide()


# -------------------------
# Common API
# -------------------------


func get_pickup_collector_module() -> PickupCollectorModule:
    return pickup_collector_module


# -------------------------
# Item API
# -------------------------


func can_add_item(item_data: ItemData, amount: int) -> bool:
    return item_data != null and amount > 0


func add_item(item_data: ItemData, amount: int) -> void:
    if item_data == null:
        Debug.warn("[loot_test_player] add_item -> item_data is null")
        return

    if item_data.id == StringName():
        Debug.warn("[loot_test_player] add_item -> empty item id")
        return

    granted_items[item_data.id] = int(granted_items.get(item_data.id, 0)) + max(1, amount)

    print("[loot_test_player] add_item -> item_id=%s amount=%s total=%s" % [String(item_data.id), amount, granted_items[item_data.id]])


# -------------------------
# Debug
# -------------------------


func reset_test_state() -> void:
    granted_items.clear()

    if stats != null:
        stats.reset_runtime_resources(reset_health_value, reset_mana_value, 0, 0)

    print("[loot_test_player] reset_test_state")


func get_debug_text() -> String:
    if stats == null:
        return "stats=n/a | items=%s" % [granted_items]

    return (
        "souls=%s | hp=%s/%s | mana=%s/%s | gold=%s | items=%s"
        % [
            stats.souls,
            stats.health,
            stats.current_max_health,
            stats.mana,
            stats.current_max_mana,
            stats.gold,
            granted_items,
        ]
    )


# -------------------------
# Internal Helpers
# -------------------------


func _wire_modules() -> void:
    if pickup_collector_module == null:
        return

    pickup_collector_module.owner_body = self
    pickup_collector_module.stats = stats
    pickup_collector_module.inventory_owner = self
