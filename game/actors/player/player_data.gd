class_name PlayerData
extends Resource

## Emitted whenever a debug mode flag changes.
## Player listens to this to re-enforce god mode ranges at runtime.
signal debug_modes_changed

# -------------------------
# Stats
# -------------------------

@export_group("Stats")
@export var stats: Stats

# -------------------------
# Weapons
# -------------------------

@export_group("Weapons")
## Weapons equipped on the player. Loaded into CombatModule at runtime.
## Index 0 is the primary equipped weapon (used by the default attack state).
## Add more entries for dual-wield or multi-weapon setups.
@export var weapons: Array[WeaponData] = []

# -------------------------
# Pickup Collection
# -------------------------

@export_group("Pickup Collection")
## Base magnet radius for loot attraction.
@export var magnet_range: float = 48.0

# -------------------------
# Debug Modes
# -------------------------

@export_group("Debug Modes")

## Undead mode — health can never drop below 1. Player cannot die.
@export var undead_mode: bool = false:
    set(value):
        undead_mode = value
        debug_modes_changed.emit()

## God mode master switch.
## When on, each sub-flag below controls which powers are active.
## When off, all god-mode powers are disabled regardless of sub-flags.
@export var god_mode: bool = false:
    set(value):
        god_mode = value
        debug_modes_changed.emit()

@export_subgroup("God Mode Powers")

## No damage — all incoming damage is ignored.
## Only active when god_mode is on.
@export var god_no_damage: bool = true:
    set(value):
        god_no_damage = value
        debug_modes_changed.emit()

## One-shot kill — attacks deal damage equal to the target's full max health.
## Only active when god_mode is on.
@export var god_oneshot: bool = true:
    set(value):
        god_oneshot = value
        debug_modes_changed.emit()

## Max range — all weapon attack ranges are overridden to a very large value.
## Only active when god_mode is on.
@export var god_max_range: bool = true:
    set(value):
        god_max_range = value
        debug_modes_changed.emit()

## The attack range applied to all attacks when god_max_range is active.
@export var god_attack_range_override: float = 1200.0:
    set(value):
        god_attack_range_override = value
        debug_modes_changed.emit()

# -------------------------
# Convenience helpers
# -------------------------


## Returns true if god_mode is on AND god_no_damage is enabled.
func is_no_damage_active() -> bool:
    return god_mode and god_no_damage


## Returns true if god_mode is on AND god_oneshot is enabled.
func is_oneshot_active() -> bool:
    return god_mode and god_oneshot


## Returns true if god_mode is on AND god_max_range is enabled.
func is_max_range_active() -> bool:
    return god_mode and god_max_range
