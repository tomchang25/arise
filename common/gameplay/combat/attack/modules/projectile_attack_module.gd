class_name ProjectileAttackModule
extends DetachedAttackModule
## Executes a Projectile-type attack.
##
## Spawns an AttackDelivery via the spawn system, then launches it.
## Motion is handled by ProjectileAttackDelivery.
##
## Reads attack_def and owner_stats from DetachedAttackModule (set via setup()).
## Reads projectile_speed directly from attack_def at fire time — no separate
## field needed on the module.

func _execute_attack_logic(target_position: Vector2) -> void:
    var data := AttackData.build(attack_def, owner_stats, self, target_position)
    if data == null:
        end_attack()
        return

    if data.attack_scene == null:
        push_error("ProjectileAttackModule: data.attack_scene is null")
        end_attack()
        return

    var action := SpawnPackedSceneAction.new()
    action.scene = data.attack_scene
    action.use_anchor_position = true
    action.use_anchor_rotation = false

    var spawn_parent := SpawnContext.resolve_spawn_parent(data.spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_error("ProjectileAttackModule: could not resolve a valid spawn parent")
        end_attack()
        return

    var ctx := SpawnContext.new()
    ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(action, global_position, ctx)

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

    delivery.setup(data)

    var def := attack_def as ProjectileAttackDefinition
    var speed := def.projectile_speed
    if delivery is ProjectileDelivery:
        (delivery as ProjectileDelivery).launch(data.knockback_dir, speed, def.travel_distance)
    elif delivery.has_method("set_speed"):
        delivery.set_speed(speed)
