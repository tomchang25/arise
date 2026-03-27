class_name PlaceAttackDefinition
extends DetachedAttackDefinition
## Spawns an AttackEffect scene at the target position and forgets it.
## Use for melee slashes, ground slams, point-blank explosions — anything
## that places a hitbox at a location and does not need to move.

@export_group("Place")
## How long the spawned AttackEffect stays alive.
@export var lifetime: float = 1.0
