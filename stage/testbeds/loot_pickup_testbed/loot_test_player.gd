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
@export var souls: int = 0
@export var mana: int = 0
@export var max_mana: int = 100
@export var gold: int = 0

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
# Resource API
# -------------------------


func can_add_souls(_value: int) -> bool:
    return true


func add_souls(value: int) -> void:
    souls += max(0, value)
    print("[loot_test_player] add_souls -> +%s | total=%s" % [value, souls])


func can_add_mana(value: int) -> bool:
    if value <= 0:
        return false

    return mana < max_mana


func add_mana(value: int) -> void:
    mana = min(max_mana, mana + max(0, value))
    print("[loot_test_player] add_mana -> +%s | mana=%s/%s" % [value, mana, max_mana])


func can_add_gold(_value: int) -> bool:
    return true


func add_gold(value: int) -> void:
    gold += max(0, value)
    print("[loot_test_player] add_gold -> +%s | total=%s" % [value, gold])


# -------------------------
# Item API
# -------------------------


func can_add_item(item_data: ItemData, amount: int) -> bool:
    return item_data != null and amount > 0


func add_item(item_data: ItemData, amount: int) -> void:
    if item_data == null:
        push_warning("[loot_test_player] add_item -> item_data is null")
        return

    if item_data.id == StringName():
        push_warning("[loot_test_player] add_item -> empty item id")
        return

    granted_items[item_data.id] = int(granted_items.get(item_data.id, 0)) + max(1, amount)

    print("[loot_test_player] add_item -> item_id=%s amount=%s total=%s" % [String(item_data.id), amount, granted_items[item_data.id]])


# -------------------------
# Debug
# -------------------------


func reset_test_state() -> void:
    souls = 0
    mana = 0
    gold = 0
    granted_items.clear()

    if stats != null:
        stats.health = min(reset_health_value, stats.current_max_health)

    print("[loot_test_player] reset_test_state")


func get_debug_text() -> String:
    var health_text := "n/a"
    if stats != null:
        health_text = "%s/%s" % [stats.health, stats.current_max_health]

    return "souls=%s | hp=%s | mana=%s/%s | gold=%s | items=%s" % [souls, health_text, mana, max_mana, gold, granted_items]


# -------------------------
# Internal Helpers
# -------------------------


func _wire_modules() -> void:
    if pickup_collector_module == null:
        return

    pickup_collector_module.owner_body = self
    pickup_collector_module.stats = stats
    pickup_collector_module.inventory_owner = self
