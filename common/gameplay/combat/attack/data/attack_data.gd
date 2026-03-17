class_name AttackData
extends RefCounted

## The scene to instantiate for fire-and-forget delivery types (Place, Projectile).
## Not used by Attached — those manage their own hitbox node.
var attack_scene: PackedScene = null

## The effect scene to mount inside the delivery at runtime.
## Instantiated and added as a child of AttackDelivery in setup().
var attack_effect_scene: PackedScene = null

## Base damage before variance: stats.current_damage * damage_multiplier
var base_damage: float = 0.0

## Variance roll added on top of base: positive or negative offset
var rolled_damage: float = 0.0

## Whether this hit is a critical strike
var is_crit: bool = false

## Crit multiplier applied when is_crit is true. Set from stats at build time.
var crit_multiplier: float = 1.5

## Final damage dealt: (base_damage + rolled_damage) * crit_multiplier if is_crit.
## This is what DamageReceiverModule reads.
var final_damage: float:
    get:
        var dmg := base_damage + rolled_damage
        if is_crit:
            dmg *= crit_multiplier
        return dmg

var max_targets: int = -1
var attack_lifetime: float = 0.2
var target_factions: Array = []

## Pre-baked travel/facing direction of the attack.
## Set for fire-and-forget types (Place, Projectile).
## HitFeedbackModule uses this when knockback_source is null.
var knockback_dir: Vector2 = Vector2.ZERO

## Live node reference to the attack origin.
## Set for Attached attacks so victims compute knockback direction
## as (victim → knockback_source) at hit time.
## Takes priority over knockback_dir in HitFeedbackModule.
var knockback_source: Node2D = null
var knockback_force: float = 0.0

var travel_distance: float = 0.0

## Seconds between repeated hits on the same victim while they remain inside the hitbox.
## 0 = hit on enter only, never repeat while inside.
## Forwarded to Hitbox.damage_interval at setup time.
var damage_interval: float = 0.0

## If true, the victim's hit record is cleared when they exit the hitbox —
## re-entering will trigger a hit again.
## If false, a victim hit once is immune for the entire hitbox lifetime.
## Forwarded to Hitbox.clear_records_on_exit at setup time.
var clear_records_on_exit: bool = true

var spawn_group: String = "attacks"

# -------------------------
# Factory
# -------------------------


## Build a fully populated AttackData from a definition + runtime caster context.
##
## For fire-and-forget types (Place, Projectile), pass target_position to bake
## knockback_dir from source → target at spawn time.
## For Attached, omit target_position — knockback_source is stored instead
## so victims compute direction at hit time.
static func build(def: AttackDefinition, stats: Stats, source: Node2D, target_position: Vector2 = Vector2.ZERO) -> AttackData:
    if def == null:
        push_error("AttackData.build: def is null")
        return null

    if stats == null:
        push_error("AttackData.build: stats is null")
        return null

    var data := AttackData.new()

    # Delivery type + scene refs
    if def is PlaceAttackDefinition:
        if def.attack_scene == null:
            push_warning("AttackData.build: PlaceAttackDefinition has no attack_scene")
            return null
        data.attack_scene = def.attack_scene
        data.attack_effect_scene = def.attack_effect_scene
        data.attack_lifetime = def.lifetime

        _bake_knockback_dir(source, target_position)

    elif def is ProjectileAttackDefinition:
        data.attack_scene = def.attack_scene
        data.attack_effect_scene = def.attack_effect_scene
        data.attack_lifetime = def.lifetime
        data.travel_distance = def.travel_distance

        _bake_knockback_dir(source, target_position)

    elif def is AttachedAttackDefinition:
        data.knockback_source = source

        # No attack_scene or effect_scene — hitbox is pre-authored in the scene.

    else:
        push_error("AttackData.build: unrecognised AttackDefinition subclass: %s" % def.get_class())
        return null

    # Damage rolls
    data.base_damage = stats.current_damage * def.damage_multiplier
    data.rolled_damage = _roll_variance(data.base_damage, def.damage_variance)
    data.is_crit = _roll_crit(stats.current_crit_chance + def.crit_bonus)
    data.crit_multiplier = stats.current_crit_multiplier

    # Hit config
    data.knockback_force = def.knockback
    data.max_targets = def.max_targets
    data.damage_interval = def.damage_interval
    data.clear_records_on_exit = def.clear_records_on_exit

    # Factions
    data.target_factions = _resolve_factions(def, stats)

    return data


# -------------------------
# Knockback
# -------------------------


static func _bake_knockback_dir(source: Node2D, target_position: Vector2) -> Vector2:
    var dir := target_position - source.global_position
    return dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT


# -------------------------
# Internal — build helpers
# -------------------------


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
            push_warning("AttackData: unknown FactionTargetType %d, defaulting to HOSTILE_ONLY" % def.faction_target_type)
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
