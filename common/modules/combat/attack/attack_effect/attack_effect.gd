class_name AttackEffect
extends Node2D

var max_targets: int = 1
var attack_lifetime: float = 0.2
var targets_hit_count: int = 0

var hitbox: Hitbox


func setup(info: AttackInfo) -> void:
    self.max_targets = info.max_targets
    _setup_lifetime(info.attack_lifetime)

    hitbox = _find_hitbox_child()
    if hitbox:
        hitbox.attack_info = info
        hitbox.hit_enemy.connect(_on_enemy_hit)


func _setup_lifetime(lifetime: float) -> void:
    if lifetime <= 0.0:
        return
    get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _find_hitbox_child() -> Hitbox:
    for child in get_children():
        if child is Hitbox:
            return child
    push_error("SlashEffect Error: No Hitbox child found in " + name)
    return null


func _on_enemy_hit() -> void:
    targets_hit_count += 1
    if max_targets > 0 and targets_hit_count >= max_targets:
        hitbox.enabled = false
