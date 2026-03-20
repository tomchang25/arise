class_name EnvironmentAttackDefinition
extends PlaceAttackDefinition
## A PlaceAttackDefinition for environment / level hazards.
##
## Identical to PlaceAttackDefinition except attack_range is hidden and
## ignored — environment attacks are placed at an arbitrary world position
## chosen by the level, not constrained by caster proximity.
##
## Authoring
## ─────────
## Create a .tres of this type. Fill in:
##   attack_scene      → your AttackDelivery scene (e.g. attack_delivery.tscn)
##   lifetime          → total duration (sum of all phase lifetimes + small buffer)
##   phases            → ordered EffectPhaseDefinitions
##   damage_multiplier → scales against the EnvironmentSpawner's Stats.base_damage
##   faction_target_type → usually ALL or HOSTILE_ONLY depending on intent
##
## Examples
## ────────
##   env_telegraph_aoe.tres   — telegraph → burst → scorch (3 phases)
##   env_toxic_cloud.tres     — DoT cloud that lingers (2 phases)
##   env_bullet_spread.tres   — DeliveryEmitter burst spread (1 phase)
