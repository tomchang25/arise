class_name VfxOnlyEffect
extends AttackEffect
## An AttackEffect that carries no Hitbox and deals no damage.
##
## Use this as the effect_scene for a pure VFX phase — scorch marks,
## lingering smoke, environmental stains, or any visual that should
## persist after the damage phase has ended.
##
## play() inherits the base AttackEffect behaviour: waits `duration` seconds
## then emits `finished`.  Override play() in a subclass if you need to drive
## a custom animation — call finished.emit() yourself at the end of it.
##
## Authoring
## ─────────
## Build a scene with this script as the root. Add whatever visual nodes you
## need (Sprite2D, CPUParticles2D, AnimationPlayer …) as children.
## Do NOT add a Hitbox child — this class deliberately skips hitbox wiring.

# -------------------------
# AttackEffect overrides
# -------------------------

## Skip hitbox wiring entirely. No error — absence of Hitbox is intentional here.
func setup(ctx: EffectContext) -> void:
    max_targets = 0
    # hitbox stays null; no wiring needed.
    # play() is inherited from AttackEffect and handles finished emission.
