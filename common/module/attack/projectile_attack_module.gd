class_name ProjectileAttackModule
extends AttackModule

@export var projectile_scene: PackedScene


func _execute_attack_logic(target_position: Vector2) -> void:
    var proj = projectile_scene.instantiate()
    # Always add projectiles to root or a dedicated manager to avoid player-transform inheritance
    get_tree().root.add_child(proj)

    proj.global_position = global_position
    proj.rotation = (target_position - global_position).angle()

    # Pass stats from Attributes
    if proj.has_node("Hurtbox"):
        var hb = proj.get_node("Hurtbox")
        hb.collision_mask = Global.get_combined_mask(target_groups)
        hb.damage = damage
        hb.max_targets = max_targets

    end_attack()
