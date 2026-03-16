class_name PlayerData
extends Resource

# -------------------------
# Stats
# -------------------------

@export_group("Stats")
@export var stats: Stats

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
@export var undead_mode: bool = false

## God mode master switch.
## When on, each sub-flag below controls which powers are active.
## When off, all god-mode powers are disabled regardless of sub-flags.
@export var god_mode: bool = false

@export_subgroup("God Mode Powers")

## No damage — all incoming damage is ignored.
## Only active when god_mode is on.
@export var god_no_damage: bool = true

## One-shot kill — attacks deal damage equal to the target's full max health.
## Only active when god_mode is on.
@export var god_oneshot: bool = true

## Max range — primary and secondary attack ranges are set to a very large value.
## Only active when god_mode is on.
@export var god_max_range: bool = true

## The attack range applied when god_max_range is active.
@export var god_attack_range_override: float = 1200.0

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
