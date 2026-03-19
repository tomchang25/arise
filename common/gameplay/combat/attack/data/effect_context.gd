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
## Phase flow
## ──────────
## • phases              — forwarded from DetachedAttackDefinition; AttackDelivery
##                         always delegates to PhaseSequencer when non-empty.
## • build_phase_override()       — forks this context for one phase. Each phase
##                         is fully authoritative over its own hit config.
## • build_for_emitted_child()    — builds a fresh context for a child delivery
##                         spawned by DeliveryEmitter. Forwards source_stats from
##                         the root caster and increments spawn_depth.
##
## Spawn depth
## ───────────
## spawn_depth tracks how many DeliveryEmitter hops separate this context from
## the original caster. DeliveryEmitter refuses to spawn when spawn_depth reaches
## DeliveryEmitter.MAX_SPAWN_DEPTH, preventing infinite chains at runtime.
##   depth 0 — context built directly by an AttackModule (root delivery)
##   depth 1 — context built for a child spawned by a DeliveryEmitter (e.g. mine)
##   depth 2 — context built for a grandchild (e.g. bullet from mine)

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
## Used by HitFeedbackModule when knockback_mode = FIXED.
var knockback_dir: Vector2 = Vector2.ZERO

## Live node reference to the attack origin for Attached attacks.
## Victims compute knockback direction as (victim → knockback_source) at hit time.
## Takes priority over knockback_dir when set (for FIXED mode on attached attacks).
var knockback_source: Node2D = null

var knockback_force: float = 0.0

## How knockback direction is computed at hit time. Forwarded from EffectPhaseDefinition.
## HitFeedbackModule reads this alongside knockback_source to resolve the final impulse.
var knockback_mode: EffectPhaseDefinition.KnockbackMode = EffectPhaseDefinition.KnockbackMode.FIXED

## Factions this attack can hit. Resolved from caster faction + definition at spawn.
var target_factions: Array = []

# -------------------------
# Hit config (forwarded to Hitbox)
# -------------------------

var max_targets: int = 1
var damage_interval: float = 0.0
var clear_records_on_exit: bool = false

# -------------------------
# Scene refs (used by PhaseEffect / AttackDelivery)
# -------------------------

var attack_scene: PackedScene = null
var attack_lifetime: float = 0.2
var travel_distance: float = 0.0
var spawn_group: String = "attacks"

## Phase array forwarded from DetachedAttackDefinition.
## Non-empty → AttackDelivery.trigger() delegates to PhaseSequencer.
var phases: Array[EffectPhaseDefinition] = []

# -------------------------
# Spawn chain tracking
# -------------------------

## Number of DeliveryEmitter hops from the original caster to this context.
## 0 = root delivery fired directly by an AttackModule.
## Incremented by build_for_emitted_child(). Checked by DeliveryEmitter against
## MAX_SPAWN_DEPTH before allowing further spawns.
var spawn_depth: int = 0

# -------------------------
# Factory — root context
# -------------------------


## Build an EffectContext from a definition + live caster context.
##
## For detached types (Place, Projectile): pass target_position to bake knockback_dir.
## For Attached: omit target_position — knockback_source is stored instead and
## hit config is read directly from the AttachedAttackDefinition.
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
    ctx.spawn_depth = 0

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
        # Hit config is owned by the definition directly (no phases on attached attacks).
        ctx.knockback_source = source
        ctx.knockback_force = def.knockback_force
        ctx.max_targets = def.max_targets
        ctx.damage_interval = def.damage_interval
        ctx.clear_records_on_exit = def.clear_records_on_exit
        # Attached attacks always use FIXED mode — direction is victim → source at hit time.
        ctx.knockback_mode = EffectPhaseDefinition.KnockbackMode.FIXED

    else:
        push_error("EffectContext.build: unrecognised AttackDefinition subclass: %s" % def.get_class())
        return null

    ctx.target_factions = _resolve_factions(def, stats)

    return ctx

# -------------------------
# Factory — child delivery context (used by DeliveryEmitter)
# -------------------------


## Build a fresh EffectContext for a child delivery spawned by a DeliveryEmitter.
##
## source_stats is forwarded from the root caster so damage scaling always
## reflects the original attacker, not an intermediate delivery.
##
## dir is the pre-baked launch direction computed by the emitter's direction fan.
##
## caller_factions is passed through so the child hits the same target set.
##
## depth is the caller's spawn_depth + 1 and is stored on the new context so
## the DeliveryEmitter depth guard can enforce MAX_SPAWN_DEPTH.
static func build_for_emitted_child(
        def: AttackDefinition,
        stats: Stats,
        origin: Vector2,
        dir: Vector2,
        caller_factions: Array,
        depth: int,
) -> EffectContext:
    if def == null:
        push_error("EffectContext.build_for_emitted_child: def is null")
        return null
    if stats == null:
        push_error("EffectContext.build_for_emitted_child: stats is null")
        return null

    var ctx := EffectContext.new()
    ctx.source_stats = stats
    ctx.definition = def
    ctx.knockback_dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT
    ctx.target_factions = caller_factions
    ctx.spawn_depth = depth

    if def is PlaceAttackDefinition:
        if def.attack_scene == null:
            push_warning("EffectContext.build_for_emitted_child: PlaceAttackDefinition has no attack_scene")
            return null
        ctx.attack_scene = def.attack_scene
        ctx.attack_lifetime = def.lifetime
        ctx.phases = def.phases

    elif def is ProjectileAttackDefinition:
        ctx.attack_scene = def.attack_scene
        ctx.attack_lifetime = def.lifetime
        ctx.travel_distance = def.travel_distance
        ctx.phases = def.phases

    else:
        push_error(
            "EffectContext.build_for_emitted_child: child_definition must be Place or Projectile, got: %s"
            % def.get_class(),
        )
        return null

    return ctx

# -------------------------
# Factory — phase fork
# -------------------------


## Fork this context for one phase.
##
## Shared spawn-time data (knockback_dir, target_factions, source_stats, definition)
## is copied by reference — baked at fire time and identical for all phases.
##
## Hit config and knockback_mode are read directly from the EffectPhaseDefinition —
## each phase is fully authoritative, no sentinel / inherit logic.
##
## spawn_depth is forwarded unchanged — phases are not a new link in the spawn
## chain; only DeliveryEmitter increments it via build_for_emitted_child.
func build_phase_override(phase_def: EffectPhaseDefinition) -> EffectContext:
    var phase_ctx := EffectContext.new()

    # Shared — baked at fire time, same for every phase.
    phase_ctx.source_stats = source_stats
    phase_ctx.definition = definition
    phase_ctx.knockback_dir = knockback_dir
    phase_ctx.knockback_source = knockback_source
    phase_ctx.target_factions = target_factions
    phase_ctx.attack_scene = attack_scene
    phase_ctx.spawn_group = spawn_group
    phase_ctx.attack_lifetime = phase_def.lifetime
    phase_ctx.spawn_depth = spawn_depth

    # Hit config — phase is fully authoritative, read directly.
    phase_ctx.knockback_mode = phase_def.knockback_mode
    phase_ctx.knockback_force = phase_def.knockback_force
    phase_ctx.max_targets = phase_def.max_targets
    phase_ctx.damage_interval = phase_def.damage_interval
    phase_ctx.clear_records_on_exit = phase_def.clear_records_on_exit

    # Phases array is not forwarded — a phase does not recurse via the sequencer.
    # DeliveryEmitter phases recursion is handled through build_for_emitted_child.
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
    var caster_faction: Stats.Faction = stats.faction

    match def.faction_target_type:
        AttackDefinition.FactionTargetType.HOSTILE_ONLY:
            return _hostile_factions(caster_faction)
        AttackDefinition.FactionTargetType.HOSTILE_AND_NEUTRAL:
            var factions := _hostile_factions(caster_faction)
            factions.append(Stats.Faction.NEUTRAL)
            return factions
        AttackDefinition.FactionTargetType.ALL:
            return [Stats.Faction.PLAYER, Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]

    return _hostile_factions(caster_faction)


static func _hostile_factions(caster_faction: Stats.Faction) -> Array:
    match caster_faction:
        Stats.Faction.PLAYER:
            return [Stats.Faction.ENEMY]
        Stats.Faction.ENEMY:
            return [Stats.Faction.PLAYER]
        _:
            return [Stats.Faction.PLAYER, Stats.Faction.ENEMY]
