class_name LootDropEntry
extends Resource

@export_group("Reward")
@export var reward_kind: LootTypes.RewardKind = LootTypes.RewardKind.RESOURCE_PICKUP
@export var pickup_scene: PackedScene

@export_group("Roll")
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export_range(1, 999, 1) var weight: int = 10
@export_range(1, 999, 1) var min_amount: int = 1
@export_range(1, 999, 1) var max_amount: int = 1

@export_group("Resource Pickup")
@export var resource_type: StringName = &""

@export_group("Item Pickup")
@export var item_id: StringName = &""
@export var item_resource: Resource
