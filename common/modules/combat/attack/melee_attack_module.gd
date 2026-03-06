class_name MeleeAttackModule
extends AttackModule

@export var max_distance: float = 30.0


func _execute_attack_logic(target_position: Vector2, info: AttackInfo) -> void:
    if info.effect_scene == null:
        end_attack()
        return

    var dir := target_position - global_position
    if dir.length_squared() <= 0.0001:
        dir = Vector2.RIGHT
    else:
        dir = dir.normalized()

    var effect_position := target_position

    if (target_position - global_position).length() > max_distance:
        effect_position = global_position + dir * max_distance

    var effect := info.effect_scene.instantiate() as AttackEffect
    if effect == null:
        push_error("MeleeAttackModule: effect_scene does not instantiate to AttackEffect")
        end_attack()
        return

    get_tree().current_scene.add_child(effect)

    effect.global_position = effect_position
    effect.rotation = dir.angle()

    if info.knockback_force <= 0.0:
        info.knockback_force = info.final_damage * 4.0

    info.knockback_dir = dir
    effect.setup(info)
