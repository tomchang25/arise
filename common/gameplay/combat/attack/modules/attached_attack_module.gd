class_name AttachedAttackModule
extends AttackModule
## Executor for AttachedAttackDefinition.
## Owns a pre-authored Hitbox node wired in by WeaponExecutor at setup time.
##
## Unified API mapping:
##   execute_attack(_target_position) → activate_attack()  (target position ignored)
##   end_attack()                     → deactivate_attack()
##
## activate_attack / deactivate_attack remain public for internal use and
## for WeaponHandle teardown, but callers should prefer execute_attack / end_attack.

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


## Activates the hitbox. target_position is ignored — hitbox is pre-authored on the actor.
## Build EffectContext and enable the hitbox.
## No-op if enabled is false or hitbox is not set.
func execute_attack(_target_position: Vector2) -> void:
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

## Deactivates the hitbox.
## Disable the hitbox.
## Always runs regardless of the enabled flag — teardown must never be suppressed.


func end_attack() -> void:
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
