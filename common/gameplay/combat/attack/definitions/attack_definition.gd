class_name AttackDefinition
extends Resource
## Base definition shared by all delivery types.
##
## Only contains fields that are universal across every attack regardless of
## how it is delivered:
##   • Damage scaling  — multiplier, variance, crit bonus (caster-level, same for all phases)
##   • Targeting       — which factions this attack can hit
##
## Hit config (knockback_force, max_targets, damage_interval, clear_records_on_exit)
## is intentionally NOT here. For detached attacks (Place, Projectile) those values
## live on each EffectPhaseDefinition so every phase can differ. For attached attacks
## they live on AttachedAttackDefinition directly, since attached attacks have no phases.
##
## Do not instantiate this directly — use PlaceAttackDefinition,
## ProjectileAttackDefinition, or AttachedAttackDefinition.

## Controls which factions this attack can hit, evaluated relative to the caster.
##
## HOSTILE_ONLY         — hits only factions that are hostile to the caster.
##                        (default; matches pre-existing behaviour)
## HOSTILE_AND_NEUTRAL  — hits hostile factions AND neutral actors.
## ALL                  — hits every faction, including the caster's own allies
##                        and the caster itself (e.g. AoE self-damage, traps).
enum FactionTargetType {
    HOSTILE_ONLY,
    HOSTILE_AND_NEUTRAL,
    ALL,
}

@export_group("Damage")
@export var damage_multiplier: float = 1.0
@export_range(0.0, 4.0, 0.01) var damage_variance: float = 0.10
@export_range(0.0, 4.0, 0.01) var crit_bonus: float = 0.0

@export_group("Targeting")
## Which factions this attack can hit. See FactionTargetType for details.
@export var faction_target_type: FactionTargetType = FactionTargetType.HOSTILE_ONLY
