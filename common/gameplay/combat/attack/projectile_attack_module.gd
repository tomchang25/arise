class_name ProjectileAttackModule
extends FireAttackModule

## Executes a Projectile-type attack.
##
## Spawns an AttackDelivery scene. AttackDelivery owns the lifetime.
## Motion is handled by child nodes inside the delivery scene (e.g. a
## Projectile node that drives velocity independently).
## Speed is injected into those child nodes via setup() if the delivery
## scene exposes it — CombatModule passes projectile_speed from the definition.

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

    var delivery := data.attack_scene.instantiate() as AttackDelivery
    if delivery == null:
        push_error("ProjectileAttackModule: attack_scene does not instantiate to AttackDelivery")
        end_attack()
        return

    get_tree().current_scene.add_child(delivery)
    delivery.global_position = global_position
    delivery.setup(data, self)

    # Start projectile motion.
    if delivery is ProjectileAttackDelivery:
        (delivery as ProjectileAttackDelivery).launch(data.knockback_dir, projectile_speed)

    # Fallback: if a custom delivery exposes set_speed(), honour it.
    elif delivery.has_method("set_speed"):
        delivery.set_speed(projectile_speed)
