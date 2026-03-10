class_name ProjectileAttackModule
extends AttackModule

@export var projectile_speed: float = 500.0


func _execute_attack_logic(target_position: Vector2, info: AttackInfo) -> void:
    if info.effect_scene == null:
        end_attack()
        return

    var dir := target_position - info.source_position
    if dir.length_squared() <= 0.0001:
        dir = Vector2.RIGHT
    else:
        dir = dir.normalized()

    var projectile := info.effect_scene.instantiate() as Projectile
    if projectile == null:
        push_error("ProjectileAttackModule: effect_scene does not instantiate to Projectile")
        end_attack()
        return

    get_tree().current_scene.add_child(projectile)
    projectile.global_position = info.source_position
    projectile.setup(info, dir, projectile_speed)
