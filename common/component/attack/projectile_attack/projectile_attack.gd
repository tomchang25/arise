@tool
class_name ProjectileAttack
extends BaseAttack

@export var projectile_scene: PackedScene


func _execute_attack_logic(target_position: Vector2) -> void:
    if global_position.distance_to(target_position) > attack_range:
        locked = false  # Unlock if out of range, or handle differently
        return

    var spawned_projectile = projectile_scene.instantiate()
    get_tree().root.add_child(spawned_projectile)

    spawned_projectile.global_position = global_position

    # Reuse the base aim logic for the projectile direction
    var aim_direction := (target_position - global_position).angle()
    spawned_projectile.rotation = aim_direction

    # Projectiles usually start cooldown immediately upon firing
    end_attack()
