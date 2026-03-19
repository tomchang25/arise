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

var attack_scene: PackedScene = null
var attack_effect_scene: PackedScene = null
var attack_lifetime: float = 0.2
var travel_distance: float = 0.0
var spawn_group: String = "attacks"

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
        ctx.attack_effect_scene = def.attack_effect_scene
        ctx.attack_lifetime = def.lifetime
        ctx.knockback_dir = _bake_knockback_dir(source, target_position)

    elif def is ProjectileAttackDefinition:
        ctx.attack_scene = def.attack_scene
        ctx.attack_effect_scene = def.attack_effect_scene
        ctx.attack_lifetime = def.lifetime
        ctx.travel_distance = def.travel_distance
        ctx.knockback_dir = _bake_knockback_dir(source, target_position)

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
##   TEAM_KILLER         — every faction except the caster's own.
##   ALL                 — every faction, including the caster's own
##                         (self-damage, traps, indiscriminate AoE).


static func _resolve_factions(def: AttackDefinition, stats: Stats) -> Array:
    var all_factions: Array = [Stats.Faction.PLAYER, Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]

    match def.faction_target_type:
        AttackDefinition.FactionTargetType.HOSTILE_ONLY:
            match stats.faction:
                Stats.Faction.PLAYER:
                    return [Stats.Faction.ENEMY]
                Stats.Faction.ENEMY:
                    return [Stats.Faction.PLAYER]
                _:
                    return []
        AttackDefinition.FactionTargetType.HOSTILE_AND_NEUTRAL:
            match stats.faction:
                Stats.Faction.PLAYER:
                    return [Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]
                Stats.Faction.ENEMY:
                    return [Stats.Faction.PLAYER, Stats.Faction.NEUTRAL]
                Stats.Faction.NEUTRAL:
                    return [Stats.Faction.PLAYER, Stats.Faction.ENEMY]
                _:
                    return []
        AttackDefinition.FactionTargetType.ALL:
            return all_factions.duplicate()
        _:
            push_warning(
                "AttackData: unknown FactionTargetType %d, defaulting to HOSTILE_ONLY" %
                def.faction_target_type,
            )
            return _resolve_factions_hostile_only(stats)


static func _resolve_factions_hostile_only(stats: Stats) -> Array:
    match stats.faction:
        Stats.Faction.PLAYER:
            return [Stats.Faction.ENEMY]
        Stats.Faction.ENEMY:
            return [Stats.Faction.PLAYER]
        _:
            return []


## Returns a signed variance offset to add onto base_value.
## variance is a 0.0–1.0 fraction of base_value as the max swing.
static func _roll_variance(base_value: float, variance: float) -> float:
    variance = max(variance, 0.0)
    if variance <= 0.0:
        return 0.0
    var max_offset := base_value * variance
    return randf_range(-max_offset, max_offset)


static func _roll_crit(chance: float) -> bool:
    return randf() < clamp(chance, 0.0, 1.0)
