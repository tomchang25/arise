class_name AttackData
extends RefCounted

enum DeliveryType { MELEE, PROJECTILE, CONTACT, CHARGE }

var slot: int = -1
var delivery_type: int = DeliveryType.MELEE

## The scene to instantiate for fire-and-forget delivery types.
## Melee expects an AttackEffect, Projectile expects a Projectile scene.
## Ignored by Contact and Charge — they manage their own hitboxes.
var attack_scene: PackedScene = null

var base_damage: float = 0.0
var rolled_damage: float = 0.0
var final_damage: float = 0.0
var is_crit: bool = false

var max_targets: int = -1
var attack_lifetime: float = 0.2
var target_factions: Array = []

var source_position: Vector2 = Vector2.ZERO
var knockback_dir: Vector2 = Vector2.ZERO
var knockback_force: float = 0.0
