class_name DetachedAttackDefinition
extends AttackDefinition
## Base for detached (fire-and-forget) delivery types (Place and Projectile).
## Do not instantiate this directly — use PlaceAttackDefinition
## or ProjectileAttackDefinition.

@export_group("Spawn")
## The delivery scene to instantiate when the attack fires.
## Root node must extend AttackDelivery.
## Controls how the attack moves and how long it lives.
@export var attack_scene: PackedScene = null

## The effect scene to mount inside the delivery at runtime.
## Root node must extend AttackEffect.
## Controls visuals, SFX, and the hitbox.
## Swap this per attack to get different slash shapes, projectile looks, etc.
@export var attack_effect_scene: PackedScene = null

@export_group("Cooldown")
@export var cooldown: float = 0.5
