class_name AttachedAttackModule
extends AttackModule
## Executor for AttachedAttackDefinition.
## Owns a pre-authored Hitbox node wired in by WeaponExecutor at setup time.
## Activation enables the hitbox; deactivation disables it.
##
## Holds attack_def and owner_stats so AttackData is built internally
## at activate time — CombatModule never builds or passes data here.
##
## Overrides activate_attack, deactivate_attack, can_attack from AttackModule.
## execute_attack / end_attack are not overridden — calls to those on an
## attached module will warn via the AttackModule base.
##
## When enabled is set to false while the hitbox is active, the hitbox is
## disabled immediately. The hitbox stays off until activate_attack() is
## called again — there is no auto-resume.

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

    var data := AttackData.build(attack_def, owner_stats, self)
    if data == null:
        return

    hitbox.attack_info = data
    hitbox.damage_interval = data.damage_interval
    hitbox.clear_records_on_exit = data.clear_records_on_exit
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
