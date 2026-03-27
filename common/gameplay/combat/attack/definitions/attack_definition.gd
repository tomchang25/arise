class_name AttackDefinition
extends Resource
## Base definition shared by all delivery types.
##
## Only contains fields that are universal across every attack regardless of
## how it is delivered:
##   • Damage scaling  — multiplier, variance, crit bonus (caster-level, same for all phases)
##   • Targeting       — which factions this attack can hit
##   • Actor behavior  — how the attacking actor animates and moves during this attack
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

@export_group("Actor Behavior")
## Animation to play immediately after perform_attack() is called, before the
## attack effect lands. Intended for telegraph-based attacks (heavy swing, beam,
## AoE) that need a visible wind-up. Leave empty to skip straight to the attack
## animation.
@export var prepare_animation: StringName = &""

## Animation to play after the prepare phase ends, while the attack effect is
## still active. Intended for channeled or casting attacks where the actor holds
## a pose until the delivery resolves (e.g. beam, sustained AoE).
## Leave empty to use the attack state's default animation_state instead.
@export var cast_animation: StringName = &""

## Index of the phase whose lifetime is used as the prepare timer duration.
## Defaults to 0 (the first phase, which is conventionally the telegraph phase).
## Ignored when prepare_animation is empty.
@export var prepare_phase_index: int = 0

## If true, the actor stops all movement for the full duration of this attack
## (prepare + cast + until attack_finished). Use for attacks where movement
## would break the visual read (e.g. heavy swing, beam).
@export var locks_movement: bool = false
