class_name ProjectileAttackModule
extends DetachedAttackModule
## Executes a Projectile-type attack.
##
## Spawns an AttackDelivery via the spawn system, then launches it.
## Builds an EffectContext at fire time so live caster stats are captured.

func _execute_attack_logic(target_position: Vector2) -> void:
    var ctx := EffectContext.build(attack_def, owner_stats, self, target_position)
    if ctx == null:
        end_attack()
        return

    if ctx.attack_scene == null:
        push_error("ProjectileAttackModule: attack_scene is null in EffectContext")
        end_attack()
        return

    var action := SpawnPackedSceneAction.create(ctx.attack_scene)
    action.use_pool = false

    var spawn_parent := SpawnContext.resolve_spawn_parent(ctx.spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_error("ProjectileAttackModule: could not resolve a valid spawn parent")
        end_attack()
        return

    var spawn_ctx := SpawnContext.new()
    spawn_ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(action, global_position, spawn_ctx)

    var result: SpawnResult = await request.execute()
    if not result.success:
        push_error("ProjectileAttackModule: spawn failed — %s" % result.blocked_reason)
        end_attack()
        return

    var delivery := result.spawned_node as AttackDelivery
    if delivery == null:
        push_error("ProjectileAttackModule: spawned node is not AttackDelivery")
        end_attack()
        return

    if not delivery.is_node_ready():
        await delivery.ready

    delivery.setup(ctx)

    var def := attack_def as ProjectileAttackDefinition
    var speed := def.projectile_speed
    if delivery is ProjectileDelivery or delivery is RpgDelivery:
        delivery.launch(ctx.knockback_dir, speed, def.travel_distance)
    elif delivery.has_method("set_speed"):
        delivery.set_speed(speed)
