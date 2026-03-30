class_name PlaceAttackModule
extends DetachedAttackModule

## Executes a Place-type attack.
##
## Spawns an AttackDelivery at the target position via the spawn system.
## Builds an EffectContext (not AttackData) at fire time so it always reflects
## the current target position and live caster stats.
func _execute_attack_logic(target_position: Vector2) -> void:
    var ctx := EffectContext.build(attack_def, owner_stats, self, target_position)
    if ctx == null:
        end_attack()
        return

    if ctx.attack_scene == null:
        push_error("PlaceAttackModule: attack_scene is null in EffectContext")
        end_attack()
        return

    var action := SpawnPackedSceneAction.create(ctx.attack_scene)
    action.use_pool = false

    var spawn_parent := SpawnContext.resolve_spawn_parent(ctx.spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_error("PlaceAttackModule: could not resolve a valid spawn parent")
        end_attack()
        return

    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(action, target_position, spawn_ctx)
    var result: SpawnResult = await request.execute()

    if not result.success:
        push_error("PlaceAttackModule: spawn failed — %s" % result.blocked_reason)
        end_attack()
        return

    var delivery := result.spawned_node as AttackDelivery
    if delivery == null:
        push_error("PlaceAttackModule: spawned node is not AttackDelivery")
        end_attack()
        return

    if not delivery.is_node_ready():
        await delivery.ready

    delivery.rotation = ctx.knockback_dir.angle()
    delivery.setup(ctx)
