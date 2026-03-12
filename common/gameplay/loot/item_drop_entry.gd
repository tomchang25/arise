class_name ItemDropEntry
extends LootDropEntry

@export_group("Item Data")
@export var item_data: ItemData


func is_item_entry() -> bool:
    return true


func _is_reward_valid() -> bool:
    return item_data != null and item_data.is_valid()
