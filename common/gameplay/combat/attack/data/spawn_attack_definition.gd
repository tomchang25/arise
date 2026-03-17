class_name SpawnAttackDefinition
extends AttackDefinition

## Base for fire-and-forget delivery types (Place and Projectile).
## Both share a cooldown and an attack_scene to instantiate.
## Do not instantiate this directly — use PlaceAttackDefinition
## or ProjectileAttackDefinition.

@export_group("Spawn")
## Scene to instantiate when the attack fires.
## Place expects an AttackEffect scene.
## Projectile expects a Projectile scene.
@export var attack_scene: PackedScene = null

@export_group("Cooldown")
@export var cooldown: float = 0.5
