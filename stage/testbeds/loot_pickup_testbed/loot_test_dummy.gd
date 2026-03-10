class_name LootTestDummy
extends Node2D

signal dummy_killed(results: Array[LootDropResult])
signal dummy_reset

@export_group("Dependencies")
@export var loot_drop_module: LootDropModule

@export_group("State")
@export var alive := true

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if loot_drop_module:
        loot_drop_module.owner_node = self


# -------------------------
# Dummy Control
# -------------------------


func kill_dummy() -> Array[LootDropResult]:
    if not alive:
        print("[loot_test_dummy] already dead")
        return []

    alive = false

    if loot_drop_module == null:
        push_warning("[loot_test_dummy] loot_drop_module is null")
        dummy_killed.emit([])
        return []

    var results := loot_drop_module.drop_loot()
    dummy_killed.emit(results)
    return results


func reset_dummy() -> void:
    alive = true
    visible = true
    dummy_reset.emit()


func set_drop_table(table: LootDropTable) -> void:
    if loot_drop_module == null:
        return
    loot_drop_module.drop_table = table


func get_drop_table() -> LootDropTable:
    if loot_drop_module == null:
        return null
    return loot_drop_module.drop_table
