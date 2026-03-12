class_name LootTestPlayer
extends CharacterBody2D

@export_group("Movement")
@export var move_speed: float = 180.0

@export_group("Debug State")
@export var souls: int = 0
@export var health: int = 50
@export var max_health: int = 100
@export var mana: int = 0
@export var max_mana: int = 100
@export var gold: int = 0

var granted_items: Dictionary = {}

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    add_to_group("player")


func _physics_process(_delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = input_dir * move_speed
    move_and_slide()


# -------------------------
# Resource API
# -------------------------


func add_souls(value: int) -> void:
    souls += max(0, value)
    print("[test_player] add_souls -> +%s | total=%s" % [value, souls])


func heal(value: int) -> void:
    health = min(max_health, health + max(0, value))
    print("[test_player] heal -> +%s | health=%s/%s" % [value, health, max_health])


func add_mana(value: int) -> void:
    mana = min(max_mana, mana + max(0, value))
    print("[test_player] add_mana -> +%s | mana=%s/%s" % [value, mana, max_mana])


func add_gold(value: int) -> void:
    gold += max(0, value)
    print("[test_player] add_gold -> +%s | total=%s" % [value, gold])


# -------------------------
# Item API
# -------------------------


func add_item(item_data: ItemData, amount: int) -> void:
    if item_data == null:
        push_warning("[test_player] add_item -> item_data is null")
        return

    if item_data.id == StringName():
        push_warning("[test_player] add_item -> empty item id")
        return

    granted_items[item_data.id] = int(granted_items.get(item_data.id, 0)) + max(1, amount)

    print("[test_player] add_item -> item_id=%s amount=%s total=%s" % [String(item_data.id), amount, granted_items[item_data.id]])


# -------------------------
# Debug
# -------------------------


func reset_test_state() -> void:
    souls = 0
    health = 50
    mana = 0
    gold = 0
    granted_items.clear()

    print("[test_player] reset_test_state")


func get_debug_text() -> String:
    return "souls=%s | hp=%s/%s | mana=%s/%s | gold=%s | items=%s" % [souls, health, max_health, mana, max_mana, gold, granted_items]
