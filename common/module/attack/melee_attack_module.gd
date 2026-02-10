class_name MeleeAttackModule
extends AttackModule

@export var melee_effect_scene: PackedScene
@export var max_distance: float = 30.0


func _execute_attack_logic(target_position: Vector2, info: AttackInfo) -> void:
    if not melee_effect_scene:
        end_attack()
        return

    var dir = (target_position - global_position).normalized()
    var effect_position = target_position
    if (target_position - global_position).length() > max_distance:
        effect_position = global_position + dir * max_distance

    var effect = melee_effect_scene.instantiate() as AttackEffect
    get_tree().current_scene.add_child(effect)

    effect.global_position = effect_position
    effect.rotation = dir.angle()

    effect.setup(info)
