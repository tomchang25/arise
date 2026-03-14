class_name LootTestDummy
extends Node2D

signal dummy_killed
signal dummy_reset

@export_group("Dependencies")
@export var loot_drop_module: LootDropModule

@export_group("State")
@export var alive := true

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    pass


# -------------------------
# Dummy Control
# -------------------------


func kill_dummy() -> void:
    if not alive:
        Debug.log("[loot_test_dummy] already dead")
        return

    alive = false

    if loot_drop_module == null:
        Debug.warn("[loot_test_dummy] loot_drop_module is null")
        dummy_killed.emit()
        return

    loot_drop_module.drop_loot()
    dummy_killed.emit()


func reset_dummy() -> void:
    alive = true
    visible = true
    dummy_reset.emit()
