class_name AttackEffect
extends Node2D

## Responsible for presentation and hitbox hosting only.
##
## AttackEffect wires the Hitbox and reacts to play() being called by
## AttackDelivery. It owns no timer and never calls queue_free.
##
## Subclasses override play(duration) to run their VFX and SFX.
## duration is provided by AttackDelivery so VFX can scale to lifetime
## without the effect needing to know about it directly.

var max_targets: int = 1
var targets_hit_count: int = 0

var hitbox: Hitbox


func setup(data: AttackData) -> void:
    max_targets = data.max_targets

    hitbox = _find_hitbox_child()
    if hitbox:
        hitbox.attack_info = data
        hitbox.damage_interval = data.damage_interval
        hitbox.clear_records_on_exit = data.clear_records_on_exit
        hitbox.hit_enemy.connect(_on_enemy_hit)


## Called by AttackDelivery after setup(). Override in subclasses to play VFX/SFX.
## duration matches the delivery lifetime — use it to scale tween lengths.
func play(_duration: float) -> void:
    pass


# -------------------------
# Internal helpers
# -------------------------


func _find_hitbox_child() -> Hitbox:
    for child in get_children():
        if child is Hitbox:
            return child
    push_error("AttackEffect: no Hitbox child found in '%s'" % name)
    return null


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_enemy_hit() -> void:
    targets_hit_count += 1
    if max_targets > 0 and targets_hit_count >= max_targets:
        hitbox.enabled = false
