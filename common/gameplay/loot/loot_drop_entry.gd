class_name LootDropEntry
extends Resource

@export_group("Drop")
@export var pickup_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export_range(1, 999, 1) var weight: int = 1
@export_range(1, 999999, 1) var min_amount: int = 1
@export_range(1, 999999, 1) var max_amount: int = 1
@export var scatter_radius: float = 20.0


func is_valid() -> bool:
    if pickup_scene == null:
        return false

    if min_amount <= 0:
        return false

    if max_amount <= 0:
        return false

    if min_amount > max_amount:
        return false

    return _is_reward_valid()


func is_resource_entry() -> bool:
    return false


func is_item_entry() -> bool:
    return false


func _is_reward_valid() -> bool:
    return false
