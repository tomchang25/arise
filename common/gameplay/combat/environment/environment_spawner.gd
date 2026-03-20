class_name EnvironmentSpawner
extends Node2D
## Level-owned node that fires environment / hazard attacks.
##
## Place one of these in each level scene. Give it:
##   • stats        — a Stats resource setting the damage level for this level.
##                    faction should be Stats.Faction.NEUTRAL (or ENEMY).
##   • attack_defs  — array of EnvironmentAttackDefinitions available in this level.
##
## Call fire(index, position) or fire_def(def, position) from any level script,
## encounter manager, or timeline to spawn an attack at an arbitrary world position.
##
## The spawner acts as the "source" node for EffectContext.build(), so
## ctx.knockback_dir is baked as (target_position - spawner.global_position).
## If direction does not matter for your attack (e.g. OUTWARD knockback_mode),
## this has no effect on gameplay.
##
## Scene setup
## ───────────
##   EnvironmentSpawner  (this script)
##     (no children required)
##
## The spawner does NOT need to be positioned near the attack site — it is a
## logical owner, not a visual. Place it anywhere convenient in the level tree.

@export_group("Identity")
## Damage level for all attacks fired from this spawner.
## Set faction to NEUTRAL or ENEMY so attacks hit the player.
@export var stats: Stats

@export_group("Attacks")
## Library of attacks available in this level.
## Index matches the argument to fire(index, position).
@export var attack_defs: Array[EnvironmentAttackDefinition] = []

@export_group("Spawn")
## Scene tree group used to parent spawned deliveries.
## Must match the group name used by your SpawnContext setup.
@export var spawn_group: String = "attacks"

# ─────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────


## Fire the attack at `index` in attack_defs at `world_position`.
## Returns the spawned AttackDelivery, or null on failure.
## Fire-and-forget — the delivery owns its own lifetime.
func fire(index: int, world_position: Vector2) -> AttackDelivery:
    if index < 0 or index >= attack_defs.size():
        push_error("EnvironmentSpawner: index %d out of range (attack_defs.size() = %d)" % [index, attack_defs.size()])
        return null
    return await fire_def(attack_defs[index], world_position)


## Fire an arbitrary EnvironmentAttackDefinition at `world_position`.
## Use this when you want to fire a def that is not in attack_defs,
## or when you hold a direct reference to the def.
func fire_def(def: EnvironmentAttackDefinition, world_position: Vector2) -> AttackDelivery:
    if def == null:
        push_error("EnvironmentSpawner: fire_def called with null def")
        return null

    if stats == null:
        push_error("EnvironmentSpawner: stats is null — assign a Stats resource in the Inspector")
        return null

    return await _spawn(def, world_position)

# ─────────────────────────────────────────────
# Internal
# ─────────────────────────────────────────────


func _spawn(def: EnvironmentAttackDefinition, world_position: Vector2) -> AttackDelivery:
    # Reuse the standard factory. Passes self as source so knockback_dir
    # is baked as (world_position - self.global_position).
    var ctx := EffectContext.build(def, stats, self, world_position)
    if ctx == null:
        push_error("EnvironmentSpawner: EffectContext.build failed for def '%s'" % def.resource_path)
        return null

    # Override spawn_group from the spawner's own export so each level can
    # route deliveries into the correct parent node.
    ctx.spawn_group = spawn_group

    if ctx.attack_scene == null:
        push_error("EnvironmentSpawner: attack_scene is null on def '%s'" % def.resource_path)
        return null

    # Resolve spawn parent via the same helper the rest of the system uses.
    var spawn_parent := SpawnContext.resolve_spawn_parent(ctx.spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_error("EnvironmentSpawner: could not resolve spawn parent for group '%s'" % spawn_group)
        return null

    var action := SpawnPackedSceneAction.new()
    action.scene = ctx.attack_scene
    action.use_anchor_position = true
    action.use_anchor_rotation = false

    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(action, world_position, spawn_ctx)

    var result: SpawnResult = await request.execute()
    if not result.success:
        push_error("EnvironmentSpawner: spawn failed — %s" % result.blocked_reason)
        return null

    var delivery := result.spawned_node as AttackDelivery
    if delivery == null:
        push_error("EnvironmentSpawner: spawned node is not AttackDelivery")
        return null

    if not delivery.is_node_ready():
        await delivery.ready

    delivery.rotation = ctx.knockback_dir.angle()
    delivery.setup(ctx)
    return delivery
