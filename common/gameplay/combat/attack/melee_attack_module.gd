class_name MeleeAttackModule
extends FireAttackModule

## Executes a Place-type (melee) attack.
##
## Spawns an AttackDelivery at the target position and calls setup().
## AttackDelivery owns the lifetime and instantiates the AttackEffect
## from data.attack_effect_scene at runtime.


func _execute_attack_logic(target_position: Vector2, data: AttackData) -> void:
    if data.attack_scene == null:
        push_error("MeleeAttackModule: data.attack_scene is null")
        end_attack()
        return

    var delivery := data.attack_scene.instantiate() as AttackDelivery
    if delivery == null:
        push_error("MeleeAttackModule: attack_scene does not instantiate to AttackDelivery")
        end_attack()
        return

    if data.knockback_force <= 0.0:
        data.knockback_force = data.final_damage * 4.0

    get_tree().current_scene.add_child(delivery)
    delivery.global_position = target_position
    delivery.rotation = data.knockback_dir.angle()
    delivery.setup(data, self)
