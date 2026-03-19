class_name AttachedAttackModule
extends AttackModule
## Executor for AttachedAttackDefinition.
## Owns a pre-authored Hitbox node wired in by WeaponExecutor at setup time.
## Activation enables the hitbox with a fresh EffectContext; deactivation disables it.

var attack_def: AttackDefinition = null
var owner_stats: Stats = null

## True while the hitbox is logically on.
var is_active: bool = false
## Injected by WeaponExecutor at setup time.
var hitbox: Hitbox = null

# -------------------------
# Setup
# -------------------------


## Called by WeaponExecutor after instantiation.
func setup(def: AttackDefinition, stats: Stats, assigned_hitbox: Hitbox) -> void:
    attack_def = def
    owner_stats = stats
    hitbox = assigned_hitbox

# -------------------------
# AttackModule overrides
# -------------------------


func can_attack() -> bool:
    return enabled and not is_active


## Build AttackData and enable the hitbox.
## No-op if enabled is false or hitbox is not set.
func activate_attack() -> void:
    if not enabled:
        return

    if hitbox == null:
        push_error("AttachedAttackModule: hitbox is not set")
        return

    if attack_def == null or owner_stats == null:
        push_error("AttachedAttackModule: attack_def or owner_stats is null — was setup() called?")
        return

    var ctx := EffectContext.build(attack_def, owner_stats, self)
    if ctx == null:
        return

    hitbox.context = ctx
    hitbox.damage_interval = ctx.damage_interval
    hitbox.clear_records_on_exit = ctx.clear_records_on_exit
    is_active = true
    _set_hitbox_active(true)


## Disable the hitbox.
## Always runs regardless of the enabled flag — teardown must never be suppressed.
func deactivate_attack() -> void:
    is_active = false
    _set_hitbox_active(false)

# -------------------------
# Internal
# -------------------------


func _set_hitbox_active(value: bool) -> void:
    if hitbox:
        hitbox.enabled = value


func _on_enabled_changed(value: bool) -> void:
    if not value:
        _set_hitbox_active(false)
    else:
        if is_active:
            _set_hitbox_active(true)
