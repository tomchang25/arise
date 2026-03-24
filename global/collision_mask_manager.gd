class_name CollisionMaskManager

const _GROUPS: Dictionary = {&"player": 1, &"enemy": 2, &"army": 9}


# --- Build ---


## Returns the layer bitmask for a single group name.
static func layer(group: StringName) -> int:
    return 1 << (_GROUPS.get(group, 0) - 1) if _GROUPS.has(group) else 0


## Returns the combined bitmask for an array of group names.
static func mask(groups: Array) -> int:
    var result := 0
    for group in groups:
        result |= layer(group)
    return result


## Returns the group name for a layer value, or &"" if not found.
static func layer_to_name(layer_value: int) -> StringName:
    for group in _GROUPS:
        if layer(group) == layer_value:
            return group
    return &""


# --- Modify ---


## Returns mask with the given group added.
static func add_group(current_mask: int, group: StringName) -> int:
    return current_mask | layer(group)


## Returns mask with the given group removed.
static func remove_group(current_mask: int, group: StringName) -> int:
    return current_mask & ~layer(group)


## Returns mask with a raw layer value added.
static func add_layer(current_mask: int, layer_value: int) -> int:
    return current_mask | layer_value


## Returns mask with a raw layer value removed.
static func remove_layer(current_mask: int, layer_value: int) -> int:
    return current_mask & ~layer_value


# --- Inspect ---


## Returns true if the mask includes the given group.
static func has_group(current_mask: int, group: StringName) -> bool:
    var l := layer(group)
    return l != 0 and (current_mask & l) != 0


## Returns true if the mask includes the given layer value.
static func has_layer(current_mask: int, layer_value: int) -> bool:
    return layer_value != 0 and (current_mask & layer_value) != 0
