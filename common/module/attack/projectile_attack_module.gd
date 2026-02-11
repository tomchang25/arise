class_name ProjectileAttackModule
extends AttackModule

@export var projectile_effect_scene: PackedScene
@export var projectile_speed: float = 500.0


func _execute_attack_logic(target_position: Vector2, info: AttackInfo) -> void:
    if not projectile_effect_scene:
        end_attack()
        return

    var dir = (target_position - global_position).normalized()

    var effect = projectile_effect_scene.instantiate() as AttackEffect
    # Add to current scene to avoid inheriting parent movement
    get_tree().current_scene.add_child(effect)

    effect.global_position = global_position
    effect.rotation = dir.angle()

    # Cast to specific effect type to set projectile-specific data
    if effect is ProjectileAttackEffect:
        effect.velocity = dir * projectile_speed

    effect.setup(info)
