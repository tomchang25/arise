class_name WeaponHandle
extends RefCounted

## Runtime container for one equipped WeaponData.
## Holds the live attack modules (one per AttackDefinition in weapon.attacks).
## Created and owned by CombatModule via WeaponExecutor.build() — never
## serialised or exported.
##
## Owns its own lookup and guard logic so CombatModule never indexes internals
## directly.


var weapon: WeaponData = null

## One module per weapon.attacks entry, index-matched.
## Each entry is a FireAttackModule or AttachedAttackModule subclass, or null
## if the definition at that index was invalid at build time.
var attack_modules: Array = []

## When false, get_module() returns null for all indices and
## CombatModule skips all attacks on this weapon.
## Toggled by CombatModule.set_weapon_enabled().
var enabled: bool = true


# -------------------------
# Lookup
# -------------------------


## Returns the attack module at attack_index, or null if:
##   - this handle is disabled
##   - attack_index is out of range
func get_module(attack_index: int) -> Object:
	if not enabled:
		return null

	if attack_index < 0 or attack_index >= attack_modules.size():
		push_warning("WeaponHandle: attack_index %d out of range for weapon '%s'" % [attack_index, weapon.weapon_name])
		return null

	return attack_modules[attack_index]


## Returns the AttackDefinition at attack_index, or null if out of range.
func get_def(attack_index: int) -> AttackDefinition:
	if attack_index < 0 or attack_index >= weapon.attacks.size():
		push_warning("WeaponHandle: attack_index %d out of range for weapon '%s'" % [attack_index, weapon.weapon_name])
		return null

	return weapon.attacks[attack_index] as AttackDefinition


# -------------------------
# Teardown
# -------------------------


## Deactivates all attached hitboxes and frees all module nodes.
## Called by CombatModule._clear_handles() on setup/teardown.
func teardown() -> void:
	for m in attack_modules:
		if m is AttachedAttackModule:
			(m as AttachedAttackModule).deactivate_attack()
		if m is Node and (m as Node).is_inside_tree():
			(m as Node).queue_free()

	attack_modules.clear()
