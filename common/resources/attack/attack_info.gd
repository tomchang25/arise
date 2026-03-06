class_name AttackInfo
extends RefCounted

var damage: float = 0.0
var max_targets: int = -1
var attack_lifetime: float = 0.2
var target_factions: Array = []

var is_crit: bool = false
var final_damage: float

# Knockback
var source_position: Vector2 = Vector2.ZERO
var knockback_dir: Vector2 = Vector2.ZERO  # if ZERO -> receiver infers from source_position
var knockback_force: float = 0.0
