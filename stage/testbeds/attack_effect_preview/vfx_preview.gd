## vfx_preview.gd
## Attach this to the root node of a bare 2D scene to preview any AttackEffect
## in isolation — no caster, no Stats, no AttackDefinition required.
##
## Scene tree
## ──────────
##   Node2D  (root, this script)
##     Camera2D
##
## Usage
## ─────
## 1. Create a new scene:  Node2D → attach this script.
## 2. Set `effect_scene` in the Inspector to the .tscn you want to preview.
## 3. Adjust `preview_duration`, `loop`, and `knockback_mode` as needed.
## 4. Run the scene with F6.  The effect plays (and loops if enabled).

extends Node2D

@export_group("Effect Under Test")
## The AttackEffect scene to preview. Must extend AttackEffect or VfxOnlyEffect.
@export var effect_scene: PackedScene

## How long to pass into effect.play(). Match the EffectPhaseDefinition lifetime.
@export var preview_duration: float = 1.5

@export_group("Playback")
## Replay the effect automatically after it finishes.
@export var loop: bool = true
## Seconds to wait between loop repetitions.
@export var loop_delay: float = 0.5

@export_group("Fake Context Values")
## Passed into ctx.max_targets. Safe to leave at 0 for VFX-only effects.
@export var max_targets: int = 0
## Knockback mode forwarded into the fake context.
@export var knockback_mode: EffectPhaseDefinition.KnockbackMode = \
        EffectPhaseDefinition.KnockbackMode.FIXED

# ─────────────────────────────────────────────
# Internal
# ─────────────────────────────────────────────

var _current_effect: AttackEffect = null


func _ready() -> void:
    if effect_scene == null:
        push_error("VfxPreview: effect_scene is not set — assign it in the Inspector.")
        return
    _play_effect()


func _play_effect() -> void:
    # Clean up any leftover instance from a previous loop iteration.
    if is_instance_valid(_current_effect):
        _current_effect.queue_free()
        _current_effect = null

    var effect := effect_scene.instantiate() as AttackEffect
    if effect == null:
        push_error("VfxPreview: effect_scene root is not an AttackEffect.")
        return

    add_child(effect)
    _current_effect = effect

    # Build a minimal fake EffectContext — only populate the fields that
    # AttackEffect.setup() and the concrete subclass actually read.
    var ctx := _build_fake_ctx()
    effect.setup(ctx)

    # Connect finished BEFORE calling play() — play() may be synchronous on
    # very short durations and emit finished before we connect otherwise.
    effect.finished.connect(_on_effect_finished, CONNECT_ONE_SHOT)
    effect.play(preview_duration)


## Construct a bare EffectContext with no real Stats or AttackDefinition.
## Fields that setup() reads are set to safe defaults.
func _build_fake_ctx() -> EffectContext:
    var ctx := EffectContext.new()
    ctx.max_targets      = max_targets
    ctx.damage_interval  = 0.0
    ctx.clear_records_on_exit = false
    ctx.knockback_dir    = Vector2.RIGHT
    ctx.knockback_mode   = knockback_mode
    ctx.knockback_force  = 0.0
    ctx.target_factions  = []
    # source_stats and definition are left null — setup() only reads them via
    # Hitbox, and VFX-only effects have no Hitbox. AttackEffects with a real
    # Hitbox will wire it but it will never fire without a Hurtbox in range.
    return ctx


func _on_effect_finished() -> void:
    if loop:
        await get_tree().create_timer(loop_delay).timeout
        _play_effect()
