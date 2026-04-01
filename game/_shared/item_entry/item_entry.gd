class_name ItemEntry
extends RefCounted

var item_data: ItemData = null

# How far the player has advanced the identity chain this run.
# 0 = base layer (always visible); max = identity_layers.size() - 1.
var layer_index: int = 0


# Returns the layer currently visible to the player.
func active_layer() -> IdentityLayer:
	return item_data.identity_layers[layer_index]


# Returns the next layer's unlock_action, or null if already at final layer.
func next_unlock_action() -> LayerUnlockAction:
	var next := layer_index + 1
	if next >= item_data.identity_layers.size():
		return null
	return item_data.identity_layers[next].unlock_action


# True if the item is veiled — inspection was not performed.
func is_veiled() -> bool:
	return layer_index == 0


# True if no further layers exist.
func is_at_final_layer() -> bool:
	return layer_index == item_data.identity_layers.size() - 1
