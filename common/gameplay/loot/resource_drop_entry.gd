class_name ResourceDropEntry
extends LootDropEntry

@export_group("Reward Data")
@export var resource_data: ResourceRewardData


func is_resource_entry() -> bool:
    return true


func _is_reward_valid() -> bool:
    return resource_data != null and resource_data.is_valid()
