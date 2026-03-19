class_name AttackEffect
extends Node2D
## Responsible for presentation and hitbox hosting only.
##
## Wires the Hitbox with an EffectContext and reacts to play() being called.
## Owns no lifetime timer — that remains on AttackDelivery for now.
## Never calls queue_free directly.
##
## Subclasses override play(duration) to run VFX and SFX.

signal finished

var max_targets: int = 1
var targets_hit_count: int = 0

var hitbox: Hitbox


func setup(ctx: EffectContext) -> void:
    max_targets = ctx.max_targets

    hitbox = _find_hitbox_child()
    if hitbox:
        hitbox.context = ctx
        hitbox.damage_interval = ctx.damage_interval
        hitbox.clear_records_on_exit = ctx.clear_records_on_exit
        hitbox.hit_enemy.connect(_on_enemy_hit)


## Called by AttackDelivery after setup(). Override in subclasses to play VFX/SFX.
## duration matches the delivery lifetime so VFX can scale to it.
func play(_duration: float = 0.0) -> void:
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
