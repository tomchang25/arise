class_name AttackDefinition
extends Resource

## Defines a single attack behaviour.
## Owned by WeaponData.attacks[]. CombatModule reads this to build AttackData
## and spawn the correct executor at setup time.

@export_group("Delivery")
@export var delivery_type: AttackData.DeliveryType = AttackData.DeliveryType.MELEE

## Required for MELEE and PROJECTILE delivery types.
## Melee expects an AttackEffect scene; Projectile expects a Projectile scene.
## Leave null for CONTACT and CHARGE — those use a HitboxSlot wired in the scene.
@export var attack_scene: PackedScene = null

@export_group("Range")
@export var attack_range: float = 40.0

@export_group("Cooldown")
## Ignored by CONTACT and CHARGE delivery types (they have no cooldown).
@export var cooldown: float = 0.5

@export_group("Damage")
@export var damage_multiplier: float = 1.0
@export_range(0.0, 4.0, 0.01) var damage_variance: float = 0.10
@export_range(0.0, 4.0, 0.01) var crit_bonus: float = 0.0

@export_group("Hit")
@export var knockback: float = 40.0
@export var lifetime: float = 0.20
@export var max_targets: int = 1

@export_group("Projectile")
## Only used when delivery_type is PROJECTILE.
@export var projectile_speed: float = 500.0
