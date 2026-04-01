class_name ItemData
extends Resource

# Internal identifier. Never displayed to the player.
@export var item_id: String = ""

# Physical classification. Holds super_category, category, weight, grid_size.
@export var category_data: CategoryData = null

# Ordered chain from least to most specific identity.
# Layer 0 has no unlock_action — always visible.
# Each subsequent layer's unlock_action describes how to advance to it.
@export var identity_layers: Array[IdentityLayer] = []


func is_valid() -> bool:
	return item_id != "" and category_data != null and identity_layers.size() > 0
