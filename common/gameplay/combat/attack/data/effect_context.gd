class_name EffectContext
extends RefCounted
## Runtime context carried by a Hitbox from spawn time through to hit resolution.
##
## Replaces AttackData as the object passed into Hitbox and Hurtbox.
## Damage is NOT pre-calculated here — DamageReceiverModule reads source_stats
## and definition at hit time so buffs are always reflected.
##
## Spawn-time snapshot fields (knockback_dir, target_factions, etc.) are baked
## once in build() because they depend on position/faction at the moment of firing.
##
## Step 2 additions
## ────────────────
## • phases          — forwarded from DetachedAttackDefinition; non-empty means the
##                     AttackDelivery should use PhaseSequencer instead of the legacy
##                     single-effect path.
## • build_phase_override() — forks this context for one phase, applying per-phase
##                     overrides without mutating the parent context.

# -------------------------
# Live references
# -------------------------

## Live stats of the caster. Read at hit time for damage calculation.
## Never snapshot — always the current state.
var source_stats: Stats = null

## The definition that produced this attack. Carries multipliers, variance, etc.
var definition: AttackDefinition = null

# -------------------------
# Spawn-time snapshot
# -------------------------

## Pre-baked travel/facing direction. Set for detached attacks (Place, Projectile).
## Baked at spawn so the direction reflects where the attack was aimed, not where
## the caster is standing when the hit lands.
var knockback_dir: Vector2 = Vector2.ZERO

## Live node reference to the attack origin for Attached attacks.
## Victims compute knockback direction as (victim → knockback_source) at hit time.
## Takes priority over knockback_dir when set.
var knockback_source: Node2D = null

var knockback_force: float = 0.0

## Factions this attack can hit. Resolved from caster faction + definition at spawn.
var target_factions: Array = []

# -------------------------
# Hit config (forwarded to Hitbox)
# -------------------------

var max_targets: int = -1
var damage_interval: float = 0.0
var clear_records_on_exit: bool = true

# -------------------------
# Scene refs (used by AttackEffect / AttackDelivery)
# -------------------------

## Legacy single-effect path. Non-null when DetachedAttackDefinition.attack_effect_scene
## is set and phases is empty. PhaseSequencer does not use this field.
var attack_scene: PackedScene = null
var attack_effect_scene: PackedScene = null
var attack_lifetime: float = 0.2
var travel_distance: float = 0.0
var spawn_group: String = "attacks"

## Phase array forwarded from DetachedAttackDefinition.phases.
## Non-empty → AttackDelivery.trigger() delegates to PhaseSequencer.
## Empty     → AttackDelivery.trigger() uses the legacy attack_effect_scene path.
var phases: Array[EffectPhaseDefinition] = []

# -------------------------
# Factory
# -------------------------


## Build an EffectContext from a definition + live caster context.
##
## For detached types (Place, Projectile): pass target_position to bake knockback_dir.
## For Attached: omit target_position — knockback_source is stored instead.
static func build(
        def: AttackDefinition,
        stats: Stats,
        source: Node2D,
        target_position: Vector2 = Vector2.ZERO,
) -> EffectContext:
    if def == null:
        push_error("EffectContext.build: def is null")
        return null
    if stats == null:
        push_error("EffectContext.build: stats is null")
        return null

    var ctx := EffectContext.new()
    ctx.source_stats = stats
    ctx.definition = def

    if def is PlaceAttackDefinition:
        if def.attack_scene == null:
            push_warning("EffectContext.build: PlaceAttackDefinition has no attack_scene")
            return null
        ctx.attack_scene = def.attack_scene
        ctx.attack_lifetime = def.lifetime
        ctx.knockback_dir = _bake_knockback_dir(source, target_position)
        ctx.phases = def.phases

    elif def is ProjectileAttackDefinition:
        ctx.attack_scene = def.attack_scene
        ctx.attack_lifetime = def.lifetime
        ctx.travel_distance = def.travel_distance
        ctx.knockback_dir = _bake_knockback_dir(source, target_position)
        ctx.phases = def.phases

    elif def is AttachedAttackDefinition:
        # No scene refs — hitbox is pre-authored in the actor scene.
        ctx.knockback_source = source

    else:
        push_error("EffectContext.build: unrecognised AttackDefinition subclass: %s" % def.get_class())
        return null

    ctx.knockback_force = def.knockback
    ctx.max_targets = def.max_targets
    ctx.damage_interval = def.damage_interval
    ctx.clear_records_on_exit = def.clear_records_on_exit
    ctx.target_factions = _resolve_factions(def, stats)

    return ctx


## Fork this context for one phase, applying EffectPhaseDefinition overrides.
##
## Shared spawn-time data (knockback_dir, target_factions, source_stats, definition)
## is copied by reference — it was baked at fire time and is identical for all phases.
## Only the hit-config fields and lifetime are overridden per phase.
##
## Sentinel values on EffectPhaseDefinition mean "inherit from parent":
##   damage_interval < 0      → use parent ctx value
##   max_targets     < 0      → use parent ctx value
##   clear_records_on_exit_override < 0 → use parent ctx value
func build_phase_override(phase_def: EffectPhaseDefinition) -> EffectContext:
    var phase_ctx := EffectContext.new()

    # Shared — baked at fire time, same for every phase.
    phase_ctx.source_stats = source_stats
    phase_ctx.definition = definition
    phase_ctx.knockback_dir = knockback_dir
    phase_ctx.knockback_source = knockback_source
    phase_ctx.knockback_force = knockback_force
    phase_ctx.target_factions = target_factions
    phase_ctx.attack_scene = attack_scene
    phase_ctx.spawn_group = spawn_group

    # Phase lifetime is always taken from the phase definition.
    phase_ctx.attack_lifetime = phase_def.lifetime

    # Hit config — apply override or inherit from parent.
    phase_ctx.damage_interval = \
    phase_def.damage_interval if phase_def.damage_interval >= 0.0 \
    else damage_interval

    phase_ctx.max_targets = \
    phase_def.max_targets if phase_def.max_targets >= 0 \
    else max_targets

    if phase_def.clear_records_on_exit_override < 0:
        phase_ctx.clear_records_on_exit = clear_records_on_exit
    else:
        phase_ctx.clear_records_on_exit = phase_def.clear_records_on_exit_override > 0

    # Phases array is not forwarded — a phase does not recurse.
    phase_ctx.phases = []

    return phase_ctx

# -------------------------
# Internal helpers
# -------------------------


static func _bake_knockback_dir(source: Node2D, target_position: Vector2) -> Vector2:
    var dir := target_position - source.global_position
    return dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT


## Resolves which factions this attack can hit, relative to the caster.
##
## FactionTargetType semantics:
##   HOSTILE_ONLY        — only factions hostile to the caster.
##   HOSTILE_AND_NEUTRAL — hostile factions + NEUTRAL actors.
##   ALL                 — every faction, including the caster's own
##                         (self-damage, traps, indiscriminate AoE).
static func _resolve_factions(def: AttackDefinition, stats: Stats) -> Array:
    var result: Array = []

    match def.faction_target_type:
        AttackDefinition.FactionTargetType.HOSTILE_ONLY:
            match stats.faction:
                Stats.Faction.PLAYER:
                    result = [Stats.Faction.ENEMY]
                Stats.Faction.ENEMY:
                    result = [Stats.Faction.PLAYER]
        AttackDefinition.FactionTargetType.HOSTILE_AND_NEUTRAL:
            match stats.faction:
                Stats.Faction.PLAYER:
                    result = [Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]
                Stats.Faction.ENEMY:
                    result = [Stats.Faction.PLAYER, Stats.Faction.NEUTRAL]
        AttackDefinition.FactionTargetType.ALL:
            result = [Stats.Faction.PLAYER, Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]

    return result
