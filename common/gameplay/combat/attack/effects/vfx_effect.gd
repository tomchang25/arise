class_name VfxEffect
extends PhaseEffect
## A PhaseEffect that carries no Hitbox and deals no damage.
##
## Use as the base for pure visual phases — scorch marks, lingering smoke,
## warning telegraphs, environmental decals, or any effect that should
## persist for a duration without interacting with the Hitbox system.
##
## play() waits `duration` seconds then emits `finished` and calls queue_free().
## Override play() in a subclass if you need a custom animation — emit
## finished.emit() yourself at the end, do NOT call super().
##
## Authoring
## ─────────
## Build a scene with this script (or a subclass) as the root.
## Add whatever visual nodes you need (Sprite2D, CPUParticles2D, Line2D …).
## Do NOT add a Hitbox child.

func setup(_ctx: EffectContext) -> void:
    pass


func play(duration: float = 0.0) -> void:
    if duration > 0.0:
        await get_tree().create_timer(duration).timeout
    finished.emit()
    queue_free()
