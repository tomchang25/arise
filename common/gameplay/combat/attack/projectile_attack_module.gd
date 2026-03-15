class_name ProjectileAttackModule
extends FireAttackModule

@export var projectile_speed: float = 500.0


func _execute_attack_logic(target_position: Vector2, data: AttackData) -> void:
    if data.attack_scene == null:
        push_error("ProjectileAttackModule: data.attack_scene is null")
        end_attack()
        return

    var dir := target_position - data.source_position
    if dir.length_squared() <= 0.0001:
        dir = Vector2.RIGHT
    else:
        dir = dir.normalized()

    var projectile := data.attack_scene.instantiate() as Projectile
    if projectile == null:
        push_error("ProjectileAttackModule: attack_scene does not instantiate to Projectile")
        end_attack()
        return

    get_tree().current_scene.add_child(projectile)
    projectile.global_position = data.source_position
    projectile.setup(data, dir, projectile_speed)
