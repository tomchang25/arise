class_name MeleeAttack
extends BaseAttack

var hurtbox: Hurtbox

## --- Virtual methods ---


func _initialize_attack() -> void:
    for child in get_children():
        if child is Hurtbox:
            hurtbox = child
            break

    if hurtbox:
        hurtbox.hit_enemy.connect(_on_enemy_hit)
    else:
        push_error("MeleeAttack must have a Hurtbox child")


func _execute_attack_logic(_target_position: Vector2) -> void:
    if hurtbox:
        hurtbox.enabled = true


func _on_enemy_hit() -> void:
    _on_hit_confirmed()


func _on_max_targets_reached() -> void:
    if hurtbox:
        hurtbox.enabled = false


## --- Overrides ---


func end_attack() -> void:
    if hurtbox:
        hurtbox.enabled = false
    super.end_attack()  # Calls the base class to start cooldown
