class_name ProjectileAttackModule
extends DetachedAttackModule
## Executes a Projectile-type attack.
##
## Spawns an AttackDelivery via the spawn system, then launches it.
## Motion is handled by child nodes inside the delivery scene.
## Speed is injected after spawn via setup() or set_speed().

## Set by CombatModule at spawn time from AttackDefinition.projectile_speed.
var projectile_speed: float = 500.0


## Called by CombatModule after instantiation.
func setup(cooldown: float, speed: float = 500.0) -> void:
    super.setup(cooldown)
    projectile_speed = speed


func _execute_attack_logic(_target_position: Vector2, data: AttackData) -> void:
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

    delivery.setup(data, self)

    if delivery is ProjectileAttackDelivery:
        (delivery as ProjectileAttackDelivery).launch(data.knockback_dir, projectile_speed)
    elif delivery.has_method("set_speed"):
        delivery.set_speed(projectile_speed)
