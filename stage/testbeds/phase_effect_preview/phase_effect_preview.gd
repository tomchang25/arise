## phase_effect_preview.gd
## Attach to the root Node2D of a bare 2D scene to preview any PhaseEffect
## subclass in isolation — HitboxEffect, VfxEffect, or DeliveryEmitter.
## No caster, no Stats, no AttackDefinition required.
##
## Location: stage/testbeds/phase_effect_preview/phase_effect_preview.gd
##
## Scene tree
## ──────────
##   Node2D  (root, this script)
##     Camera2D
##
## Usage
## ─────
## 1. Create a scene: Node2D → attach this script.
## 2. Set `effect_scene` in the Inspector to the .tscn you want to preview.
## 3. Adjust `preview_duration`, `loop`, `loop_delay` as needed.
## 4. For HitboxEffect: set `max_targets` and `knockback_mode`.
## 5. Run with F6.
extends Node2D

# ─────────────────────────────────────────────
# Inspector
# ─────────────────────────────────────────────

@export_group("Effect Under Test")
## Any PhaseEffect subclass: HitboxEffect, VfxEffect, or DeliveryEmitter.
@export var effect_scene: PackedScene
## Passed into effect.play(). Match the EffectPhaseDefinition lifetime.
@export var preview_duration: float = 1.5

@export_group("Playback")
## Replay automatically after the effect finishes.
@export var loop: bool = true
## Seconds between loop repetitions.
@export var loop_delay: float = 0.5

@export_group("HitboxEffect Context")
## Only used when the effect extends HitboxEffect.
## Safe to leave at 0 for VfxEffect and DeliveryEmitter.
@export var max_targets: int = 0
@export var knockback_mode: EffectPhaseDefinition.KnockbackMode = EffectPhaseDefinition.KnockbackMode.FIXED

# ─────────────────────────────────────────────
# Internal
# ─────────────────────────────────────────────

var _current_effect: PhaseEffect = null


func _ready() -> void:
    if effect_scene == null:
        push_error("PhaseEffectPreview: effect_scene is not set — assign it in the Inspector.")
        return
    _play_effect()


func _play_effect() -> void:
    if is_instance_valid(_current_effect):
        _current_effect.queue_free()
        _current_effect = null

    var effect := effect_scene.instantiate() as PhaseEffect
    if effect == null:
        push_error("PhaseEffectPreview: effect_scene root does not extend PhaseEffect.")
        return

    add_child(effect)
    _current_effect = effect

    var ctx := _build_ctx_for(effect)
    effect.setup(ctx)

    # Connect before play() — a very short duration could emit finished
    # synchronously before a post-play() connect would register.
    effect.finished.connect(_on_effect_finished, CONNECT_ONE_SHOT)
    effect.play(preview_duration)


## Build a minimal fake EffectContext appropriate for the concrete effect type.
func _build_ctx_for(effect: PhaseEffect) -> EffectContext:
    var ctx := EffectContext.new()
    ctx.knockback_dir = Vector2.RIGHT
    ctx.knockback_force = 0.0
    ctx.target_factions = []
    ctx.spawn_depth = 0

    if effect is AttackEffect:
        # HitboxEffect reads max_targets, damage_interval, clear_records_on_exit,
        # and knockback_mode from the context in setup().
        ctx.max_targets = max_targets
        ctx.damage_interval = 0.0
        ctx.clear_records_on_exit = false
        ctx.knockback_mode = knockback_mode
        # source_stats and definition left null — Hitbox wires fine but will
        # never fire without a real Hurtbox in range.

    elif effect is VfxEffect:
        # VfxEffect.setup() ignores ctx entirely; defaults are sufficient.
        pass

    elif effect is DeliveryEmitter:
        # DeliveryEmitter reads source_stats via build_for_emitted_child.
        # In preview we skip actual spawning — the emitter will push an error
        # about missing definition and finish cleanly. That's acceptable here.
        pass

    return ctx


func _on_effect_finished() -> void:
    if loop:
        await get_tree().create_timer(loop_delay).timeout
        _play_effect()
