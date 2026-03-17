class_name AttackDefinition
extends Resource

## Base definition shared by all delivery types.
## Only contains fields relevant to every attack regardless of how it is delivered.
## Do not instantiate this directly — use PlaceAttackDefinition,
## ProjectileAttackDefinition, or AttachedAttackDefinition.

@export_group("Damage")
@export var damage_multiplier: float = 1.0
@export_range(0.0, 4.0, 0.01) var damage_variance: float = 0.10
@export_range(0.0, 4.0, 0.01) var crit_bonus: float = 0.0

@export_group("Hit")
@export var knockback: float = 40.0
@export var max_targets: int = 1

## Seconds between repeated hits on the same victim while they remain inside the hitbox.
## 0 = hit on enter only, never repeat while inside.
@export var damage_interval: float = 0.0

## If true, the victim's hit record is cleared when they exit the hitbox —
## re-entering will trigger a hit again.
## If false, a victim hit once is immune for the entire hitbox lifetime.
@export var clear_records_on_exit: bool = false
