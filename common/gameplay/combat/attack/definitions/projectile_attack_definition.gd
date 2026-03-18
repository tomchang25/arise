class_name ProjectileAttackDefinition
extends DetachedAttackDefinition
## Spawns a Projectile scene that carries the hitbox to the target.
## The projectile moves autonomously after launch — no further control needed.

@export_group("Projectile")
## Maximum distance the projectile will travel before self-destructing.
@export var travel_distance: float = 400.0

## How long the projectile stays alive regardless of distance travelled.
@export var lifetime: float = 5.0

## Movement speed of the projectile in pixels per second.
@export var projectile_speed: float = 500.0
