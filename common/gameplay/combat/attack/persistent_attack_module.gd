class_name PersistentAttackModule
extends Node2D

## When false, activate_attack() is a no-op.
## Setting to false while the hitbox is active suspends it immediately —
## _deactivate_logic() is called and the AttackData is cached.
## Setting back to true while suspended resumes it — _activate_logic() is
## called again with the cached data, restoring the hitbox to its prior state.
## deactivate_attack() always runs regardless of this flag.
var enabled: bool = true:
    set(value):
        if enabled == value:
            return
        enabled = value
        if not enabled and is_active:
            _deactivate_logic()
        elif enabled and _cached_data != null:
            _activate_logic(_cached_data)

## True while the hitbox is logically active (i.e. activate_attack has been
## called and deactivate_attack has not). Remains true while suspended —
## reflects intent, not the current hitbox state.
## Read by external systems to query whether this executor is in-flight.
var is_active: bool = false

## Retained copy of the last AttackData passed to activate_attack.
## Used to restore state when enabled is set back to true after a suspend.
var _cached_data: AttackData = null

# -------------------------
# Common API
# -------------------------


## Enable the persistent hitbox with the given attack data.
## No-op if enabled is false.
func activate_attack(data: AttackData) -> void:
    if not enabled:
        return

    if data == null:
        push_error("PersistentAttackModule: data is null")
        return

    is_active = true
    _cached_data = data
    _activate_logic(data)


## Disable the persistent hitbox.
## Always runs regardless of the enabled flag — teardown must never be suppressed.
## Clears cached data so a future re-enable does not auto-resume.
func deactivate_attack() -> void:
    is_active = false
    _cached_data = null
    _deactivate_logic()


# -------------------------
# Internal — override in subclasses
# -------------------------


func _activate_logic(_data: AttackData) -> void:
    pass


func _deactivate_logic() -> void:
    pass
