class_name Attack
extends RefCounted

## The final damage number applied for this specific attack instance.
var damage: float = 0.0

## Other dynamic, instance-specific variables (e.g., critical hit status, target type)
var is_critical: bool = false
var source_node: Node = null

## Optional: A reference to the static data
var data: AttackData
