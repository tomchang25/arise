class_name MeleeAttackModule
extends FireAttackModule


func _execute_attack_logic(target_position: Vector2, data: AttackData) -> void:
    if data.attack_scene == null:
        push_error("MeleeAttackModule: data.attack_scene is null")
        end_attack()
        return

    var effect := data.attack_scene.instantiate() as AttackEffect
    if effect == null:
        push_error("MeleeAttackModule: attack_scene does not instantiate to AttackEffect")
        end_attack()
        return

    get_tree().current_scene.add_child(effect)
    effect.global_position = target_position
    effect.rotation = data.knockback_dir.angle()

    if data.knockback_force <= 0.0:
        data.knockback_force = data.final_damage * 4.0

    effect.setup(data)
