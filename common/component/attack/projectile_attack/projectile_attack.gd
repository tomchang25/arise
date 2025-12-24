@tool
class_name ProjectileAttack
extends BaseAttack

@export var projectile_scene: PackedScene
@export var damage:=10

func _execute_attack_logic(target_position: Vector2) -> void:
    var spawned_projectile: Projectile = projectile_scene.instantiate()
    get_tree().root.add_child(spawned_projectile)
    
    spawned_projectile.hurtbox.collision_mask = Global.get_combined_mask(target_groups)
    spawned_projectile.global_position = global_position
    spawned_projectile.max_pierce = max_targets
    spawned_projectile.damage = damage

    # Reuse the base aim logic for the projectile direction
    var aim_direction := (target_position - global_position).angle()
    spawned_projectile.rotation = aim_direction

    # Projectiles usually start cooldown immediately upon firing
    end_attack()
