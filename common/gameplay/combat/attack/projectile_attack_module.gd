class_name ProjectileAttackModule
extends FireAttackModule

## Set by CombatModule at spawn time from AttackDefinition.projectile_speed.
var projectile_speed: float = 500.0


## Called by CombatModule after instantiation.
## Injects both cooldown (via super) and projectile speed.
func setup(cooldown: float, speed: float = 500.0) -> void:
    super.setup(cooldown)
    projectile_speed = speed


func _execute_attack_logic(_target_position: Vector2, data: AttackData) -> void:
    if data.attack_scene == null:
        push_error("ProjectileAttackModule: data.attack_scene is null")
        end_attack()
        return

    var projectile := data.attack_scene.instantiate() as Projectile
    if projectile == null:
        push_error("ProjectileAttackModule: attack_scene does not instantiate to Projectile")
        end_attack()
        return

    get_tree().current_scene.add_child(projectile)
    projectile.global_position = global_position
    projectile.setup(data, data.knockback_dir, projectile_speed)
