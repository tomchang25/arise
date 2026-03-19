class_name AttackEffect
extends Node2D
## Responsible for presentation and hitbox hosting only.
##
## Wires the Hitbox with an EffectContext and reacts to play() being called.
## Owns no lifetime timer — that remains on AttackDelivery for now.
## Never calls queue_free directly.
##
## Hitbox is optional.
## A subclass or scene that has no Hitbox child is a VFX-only effect and will
## deal no damage. Use VfxOnlyEffect as a ready-made base for that case.
##
## play() and finished
## ───────────────────
## The base play() waits `duration` seconds then emits `finished`.
## This means a plain AttackEffect scene (hitbox active for the phase lifetime,
## no custom animation) works correctly with PhaseSequencer out of the box —
## the hitbox stays active for exactly `duration` seconds, then the sequencer
## advances to the next phase.
##
## Subclasses that manage their own animation timing (SlashAttackEffect, etc.)
## override play() WITHOUT calling super(), then emit finished.emit() themselves
## at the end of their animation.  The base timer never runs in that case.

signal finished

var max_targets: int = 1
var targets_hit_count: int = 0

## Null when no Hitbox child exists (VFX-only effect).
var hitbox: Hitbox


func setup(ctx: EffectContext) -> void:
    max_targets = ctx.max_targets

    hitbox = _find_hitbox_child()
    if hitbox:
        hitbox.context = ctx
        hitbox.damage_interval = ctx.damage_interval
        hitbox.clear_records_on_exit = ctx.clear_records_on_exit
        hitbox.hit_enemy.connect(_on_enemy_hit)


## Called by PhaseSequencer (or AttackDelivery legacy path) after setup().
##
## Base behaviour: keep the hitbox active for `duration` seconds, then emit
## `finished` so the sequencer can advance to the next phase.
##
## Override in subclasses that run their own timed animation.
## Do NOT call super() in those overrides — emit finished.emit() yourself
## at the end of the animation instead.
func play(duration: float = 0.0) -> void:
    if duration > 0.0:
        await get_tree().create_timer(duration).timeout
    finished.emit()
    queue_free()

# -------------------------
# Internal helpers
# -------------------------


## Returns the first Hitbox child, or null if none exists.
## Null is valid — it means this is a VFX-only effect.
func _find_hitbox_child() -> Hitbox:
    for child in get_children():
        if child is Hitbox:
            return child
    return null

# -------------------------
# Signals / Callbacks
# -------------------------


func _on_enemy_hit() -> void:
    targets_hit_count += 1
    if max_targets > 0 and targets_hit_count >= max_targets:
        hitbox.enabled = false
