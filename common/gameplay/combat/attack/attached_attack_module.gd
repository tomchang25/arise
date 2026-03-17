class_name AttachedAttackModule
extends Node2D

## Executor for AttachedAttackDefinition.
## Owns a pre-authored Hitbox node wired in by CombatModule at setup time.
## Activation enables the hitbox; deactivation disables it. That's it.
##
## When enabled is set to false while the hitbox is active, the hitbox is
## disabled immediately. The hitbox stays off until activate_attack() is
## called again — there is no auto-resume.

## When false, activate_attack() is a no-op and the hitbox is disabled immediately.
var enabled: bool = true:
    set(value):
        if enabled == value:
            return
        enabled = value
        if not enabled:
            _set_hitbox_active(false)
        else:
            if is_active:
                _set_hitbox_active(true)
## True while the hitbox is logically on.
## Read by external systems to query whether this executor is in-flight.
var is_active: bool = false

## Injected by CombatModule at setup time. Never set this in the inspector.
var hitbox: Hitbox = null

# -------------------------
# Setup
# -------------------------


## Called by CombatModule after instantiation to inject the hitbox reference.
func setup(assigned_hitbox: Hitbox) -> void:
    hitbox = assigned_hitbox


# -------------------------
# API
# -------------------------


## Enable the hitbox with the given attack data.
## No-op if enabled is false or hitbox is not set.
func activate_attack(data: AttackData) -> void:
    if not enabled:
        return

    if hitbox == null:
        push_error("AttachedAttackModule: hitbox is not set")
        return

    if data == null:
        push_error("AttachedAttackModule: data is null")
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
