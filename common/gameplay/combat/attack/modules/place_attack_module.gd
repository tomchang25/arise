class_name PlaceAttackModule
extends DetachedAttackModule
## Executes a Place-type attack.
##
## Spawns an AttackDelivery at the target position via the spawn system.
## AttackDelivery owns the lifetime and instantiates the AttackEffect
## from data.attack_effect_scene at runtime.

func _execute_attack_logic(target_position: Vector2, data: AttackData) -> void:
    if data.attack_scene == null:
        push_error("PlaceAttackModule: data.attack_scene is null")
        end_attack()
        return

    if data.knockback_force <= 0.0:
        data.knockback_force = data.final_damage * 4.0

    var action := SpawnPackedSceneAction.new()
    action.scene = data.attack_scene
    action.use_anchor_position = true
    action.use_anchor_rotation = false

    var spawn_parent := SpawnContext.resolve_spawn_parent(data.spawn_group, self)
    if not is_instance_valid(spawn_parent):
        push_error("PlaceAttackModule: could not resolve a valid spawn parent")
        end_attack()
        return

    var ctx := SpawnContext.new()
    ctx.setup(spawn_parent, 0, self)

    var request := SpawnRequest.new()
    request.setup_direct(action, target_position, ctx)
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

    delivery.rotation = data.knockback_dir.angle()
    delivery.setup(data, self)
