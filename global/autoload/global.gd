extends Node

const GROUP_TO_LAYER = {&"player": 1, &"enemy": 2, &"army": 9}


## Returns the bitmask for a single layer name
func get_mask_from_name(mask_name: String) -> int:
    if GROUP_TO_LAYER.has(mask_name):
        var layer_num = GROUP_TO_LAYER[mask_name]
        return int(pow(2, layer_num - 1))

    push_warning("Layer name '" + mask_name + "' not found in GROUP_TO_LAYER")
    return 0


## Returns a combined mask for multiple names (e.g., ["player", "enemy"])
func get_combined_mask(mask_names: Array) -> int:
    var total_mask = 0
    for mask_name in mask_names:
        total_mask |= get_mask_from_name(mask_name)
    return total_mask
