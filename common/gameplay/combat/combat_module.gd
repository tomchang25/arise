class_name CombatModule
extends Node2D
## Manages all weapons on an actor.
##
## Setup:
##   1. Assign `stats` (actor's Stats resource).
##   2. Assign `hitbox_slots` (pre-authored Hitbox nodes in the scene) for any
##      ATTACHED weapons. Detached types need no hitbox slots.
##   3. Assign `weapons` array (WeaponData resources).
##   4. Call setup() — or it is called automatically in _ready().
##
## Hitbox binding for ATTACHED attacks:
##   Each AttachedAttackDefinition must set hitbox_slot_id to match the slot_id of
##   its intended Hitbox node in hitbox_slots. Order in hitbox_slots is irrelevant.
##
## API (weapon_index = index in `weapons`, attack_index = index in weapon.attacks):
##
##   Unified attack (works for both detached and attached):
##     perform_attack(weapon_index, attack_index, target_position, auto_end)
##     end_attack(weapon_index, attack_index)
##     can_attack(weapon_index, attack_index) -> bool
##
##   For attached attacks:
##     perform_attack → activates the hitbox   (target_position ignored)
##     end_attack     → deactivates the hitbox
##     auto_end param is ignored for attached attacks
##
##   Weapon switch:
##     set_weapon_enabled(weapon_index, enabled)
##
##   Range overrides (god mode, buffs, debuffs):
##     set_attack_range_override(weapon_index, attack_index, value)
##     clear_attack_range_override(weapon_index, attack_index)
##     clear_all_range_overrides()
##     get_attack_range(weapon_index, attack_index) -> float

@export var stats: Stats
@export_group("Weapons")
## WeaponData resources to equip on this actor.
## Index matches weapon_index used in all API calls.
@export var weapons: Array[WeaponData] = []
@export_group("Hitbox Slots")
## Pre-authored Hitbox nodes for ATTACHED attacks.
## Order does not matter — each AttachedAttackDefinition binds by hitbox_slot_id.
@export var hitbox_slots: Array[Hitbox] = []

# -------------------------
# Runtime state
# -------------------------
## WeaponHandle instances, index-matched to `weapons`.
var _handles: Array[WeaponHandle] = []
## Range overrides keyed by "wi_ai" string (weapon_index + attack_index).
## When a key exists, get_attack_range() returns its value instead of the
## AttackDefinition base. Does NOT mutate weapon resources.
var _range_overrides: Dictionary = { }

# -------------------------
# Lifecycle
# -------------------------


## Build all WeaponHandles from the current `weapons` array.
## Safe to call again if weapons change at runtime (clears and rebuilds).
func setup(owner_stats := stats) -> void:
    stats = owner_stats

    _clear_handles()

    for weapon in weapons:
        var handle := WeaponExecutor.build(weapon, self, hitbox_slots, stats)
        _handles.append(handle)


## Replace the equipped weapons with duplicates of the given array, then rebuild.
## Duplicating ensures runtime overrides don't write back into the source resources.
func equip_weapons(source_weapons: Array[WeaponData]) -> void:
    weapons.clear()
    for weapon in source_weapons:
        if weapon != null:
            weapons.append(weapon.duplicate() as WeaponData)
    setup()


# -------------------------
# Attack API
# -------------------------
## Execute an attack for any module type.
##
## Detached (Projectile, Place, Trap):
##   Fires once toward target_position.
##   auto_end=true starts the cooldown immediately.
##   Pass auto_end=false and call end_attack() from animation_finished to defer cooldown.
##
## Attached (persistent hitbox):
##   Activates the hitbox. target_position and auto_end are ignored.
##   Call end_attack() to deactivate.
func perform_attack(weapon_index: int, attack_index: int, target_position: Vector2 = Vector2.ZERO) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    var module := handle.get_module(attack_index)
    if module == null:
        return

    if not module.enabled or not module.can_attack():
        return

    # Range clamp is place-specific — only PlaceAttackModule carries an attack_range.
    if module is PlaceAttackModule:
        var effective_range := get_attack_range(weapon_index, attack_index)
        var distance := global_position.distance_to(target_position)
        if distance > effective_range + 0.01:
            Debug.warn("CombatModule: target out of range (%.1f > %.1f)" % [distance, effective_range])
            var dir := (target_position - global_position).normalized()
            target_position = global_position + dir * effective_range

    module.execute_attack(target_position)


## End the attack for the given weapon / attack index.
##
## Detached: starts the cooldown timer.
## Attached: deactivates the hitbox.
##
## Uses direct array access to bypass the handle enabled guard —
## teardown must always be allowed even on a disabled weapon.
func end_attack(weapon_index: int, attack_index: int) -> void:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    if attack_index < 0 or attack_index >= handle.attack_modules.size():
        return

    var module = handle.attack_modules[attack_index]
    if module:
        module.end_attack()


## Returns true if the module is ready to attack.
func can_attack(weapon_index: int, attack_index: int) -> bool:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return false

    var module := handle.get_module(attack_index)
    if module == null:
        return false

    return module.can_attack()


# -------------------------
# Weapon enable / disable
# -------------------------
## Enable or disable an entire weapon.
## This gates future perform_attack calls on all modules in this weapon.
## It does NOT deactivate any currently live attached hitboxes —
## call end_attack() explicitly before disabling if immediate teardown is needed.
func set_weapon_enabled(weapon_index: int, value: bool) -> void:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    handle.enabled = value

    for module in handle.attack_modules:
        module.enabled = value


# -------------------------
# Range override API
# -------------------------
## Returns the effective attack range for the given weapon/attack.
## If a range override is active, that value is returned instead.
## Only PlaceAttackDefinition carries a range — Projectile and Attached return 0.
func get_attack_range(weapon_index: int, attack_index: int = 0) -> float:
    var key := _range_key(weapon_index, attack_index)
    if _range_overrides.has(key):
        return _range_overrides[key]

    var handle := _get_handle(weapon_index)
    if handle == null:
        return 0.0

    var def := handle.get_def(attack_index)
    if def is PlaceAttackDefinition:
        return def.attack_range

    return 0.0


## Set a runtime range override for a specific weapon/attack.
## Does not mutate weapon resources — override is stored separately.
func set_attack_range_override(weapon_index: int, attack_index: int, value: float) -> void:
    _range_overrides[_range_key(weapon_index, attack_index)] = value


## Remove the range override for a specific weapon/attack.
## Restores get_attack_range() to the definition base value.
func clear_attack_range_override(weapon_index: int, attack_index: int) -> void:
    _range_overrides.erase(_range_key(weapon_index, attack_index))


## Remove all range overrides.
func clear_all_range_overrides() -> void:
    _range_overrides.clear()


# -------------------------
# Internal
# -------------------------
func _get_handle(weapon_index: int) -> WeaponHandle:
    if weapon_index < 0 or weapon_index >= _handles.size():
        push_warning("CombatModule: weapon_index %d out of range" % weapon_index)
        return null
    return _handles[weapon_index]


func _clear_handles() -> void:
    for handle in _handles:
        if handle != null:
            handle.teardown()
    _handles.clear()


func _range_key(weapon_index: int, attack_index: int) -> String:
    return "%d_%d" % [weapon_index, attack_index]
