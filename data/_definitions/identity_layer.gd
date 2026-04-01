class_name IdentityLayer
extends Resource

# The name shown to the player when this layer is the active read.
@export var display_label: String = ""

# Base market value at this layer of understanding.
# Used as the anchor for price estimates at inspection and auction.
# The last layer's base_value is the item's true value.
@export var base_value: int = 0

# Action required to unlock this layer from the previous one.
# Null on layer 0 — always visible, no action needed.
@export var unlock_action: LayerUnlockAction = null
