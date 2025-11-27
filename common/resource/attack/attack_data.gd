class_name AttackData
extends Resource

## The base damage value. Since it's a float by a certain amplitude,
## the amplitude can be stored here for consistency.
@export var base_damage: float = 1.0

## Any other static parameters (e.g., knockback force, element type, sound FX path)
@export var knockback_force: float = 50.0
@export var element_type: String = "Normal"
