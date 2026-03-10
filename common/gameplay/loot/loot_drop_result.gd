class_name LootDropResult
extends RefCounted

var reward_kind: LootTypes.RewardKind = LootTypes.RewardKind.RESOURCE_PICKUP
var pickup_scene: PackedScene

var amount: int = 1
var resource_type: StringName = &""

var item_id: StringName = &""
var item_resource: Resource
