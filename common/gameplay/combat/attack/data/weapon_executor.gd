class_name WeaponExecutor
extends RefCounted

## Runtime container for one equipped WeaponData.
## Holds the live executor nodes (one per AttackDefinition in weapon.attacks).
## Created and owned by CombatModule — never serialised or exported.

var weapon: WeaponData = null

## One executor per weapon.attacks entry, index-matched.
## Each entry is either a FireAttackModule or a PersistentAttackModule subclass.
var attack_executors: Array = []

## When false, CombatModule silently skips all attacks on this weapon.
## Toggled by CombatModule.set_weapon_enabled() — useful for disabling a weapon
## during a specific phase (e.g. charge bear disables normal weapons while charging).
var enabled: bool = true
