class_name CategoryData
extends Resource

# Broad item type (e.g. "Fine Art", "Vehicle").
@export var super_category: String = ""

# Fine-grained item type (e.g. "Painting", "Pocket Watch").
@export var category: String = ""

# Weight in kilograms.
@export var weight: float = 0.0

# Number of inventory grid cells this item occupies.
@export var grid_size: int = 1
