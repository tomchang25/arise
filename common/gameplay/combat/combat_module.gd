class_name CombatModule
extends Node2D

## Manages all weapons on an actor.
##
## Setup:
##   1. Assign `stats` (actor's Stats resource).
##   2. Assign `hitbox_slots` (pre-authored Hitbox nodes in the scene) for any
##      ATTACHED weapons. Fire-and-forget types need no hitbox slots.
##   3. Assign `weapons` array (WeaponData resources).
##   4. Call setup() — or it is called automatically in _ready().
##
## API (weapon_index = index in `weapons`, attack_index = index in weapon.attacks):
##
##   Fire-and-forget:
##     perform_attack(weapon_index, attack_index, target_position, auto_end)
##     end_attack(weapon_index, attack_index)
##     can_attack(weapon_index, attack_index) -> bool
##
##   Attached (persistent hitbox):
##     activate_attack(weapon_index, attack_index)
##     deactivate_attack(weapon_index, attack_index)
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
## Assigned in order as attached weapons are set up.
## Add as many as the actor has attached attack types.
@export var hitbox_slots: Array[Hitbox] = []

# -------------------------
# Runtime state
# -------------------------

## WeaponHandle instances, index-matched to `weapons`.
var _handles: Array[WeaponHandle] = []

## Next hitbox slot to claim for an Attached executor.
var _next_hitbox_slot: int = 0

## Range overrides keyed by "wi_ai" string (weapon_index + attack_index).
## When a key exists, get_attack_range() returns its value instead of the
## AttackDefinition base. Does NOT mutate weapon resources.
var _range_overrides: Dictionary = {}

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    setup()


## Build all WeaponHandles from the current `weapons` array.
## Safe to call again if weapons change at runtime (clears and rebuilds).
func setup() -> void:
    _clear_handles()
    _next_hitbox_slot = 0

    for weapon in weapons:
        var handle := WeaponExecutor.build(weapon, self, hitbox_slots, _next_hitbox_slot)
        if handle != null:
            for m in handle.attack_modules:
                if m is AttachedAttackModule:
                    _next_hitbox_slot += 1
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
# Fire-and-forget API
# -------------------------


## Execute a one-shot attack.
## auto_end=true starts the cooldown immediately.
## Pass auto_end=false and call end_attack() from animation_finished to defer cooldown.
func perform_attack(weapon_index: int, attack_index: int, target_position: Vector2, auto_end: bool = true) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    var module := handle.get_module(attack_index)
    if module == null:
        return

    var fire := module as FireAttackModule
    if fire == null:
        push_error("CombatModule: perform_attack called on an attached module (weapon %d, attack %d)" % [weapon_index, attack_index])
        return

    if not fire.enabled or not fire.can_attack():
        return

    if module is MeleeAttackModule:
        var effective_range := get_attack_range(weapon_index, attack_index)
        var distance := global_position.distance_to(target_position)
        if distance > effective_range + 0.01:
            Debug.warn("CombatModule: target out of range (%.1f > %.1f)" % [distance, effective_range])
            var dir := (target_position - global_position).normalized()
            target_position = global_position + dir * effective_range

    var def := handle.get_def(attack_index)
    var data := AttackData.build(def, stats, self, target_position)
    if data == null:
        return

    fire.execute_attack(target_position, data)

    if auto_end:
        fire.end_attack()


## Start the cooldown for a fire executor.
## Call from animation_finished when using auto_end=false.
func end_attack(weapon_index: int, attack_index: int) -> void:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    var module := handle.get_module(attack_index)
    if module is FireAttackModule:
        (module as FireAttackModule).end_attack()


## Returns true if the fire executor is ready to attack.
func can_attack(weapon_index: int, attack_index: int) -> bool:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return false

    var module := handle.get_module(attack_index)
    if module is FireAttackModule:
        return (module as FireAttackModule).can_attack()

    return false


# -------------------------
# Attached API
# -------------------------


## Enable the attached hitbox for the given weapon / attack index.
func activate_attack(weapon_index: int, attack_index: int) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    var module := handle.get_module(attack_index)
    if module == null:
        return

    var attached := module as AttachedAttackModule
    if attached == null:
        push_error("CombatModule: activate_attack called on a fire module (weapon %d, attack %d)" % [weapon_index, attack_index])
        return

    if not attached.enabled:
        return

    var def := handle.get_def(attack_index)
    var data := AttackData.build(def, stats, self)
    if data == null:
        return

    attached.activate_attack(data)


## Disable the attached hitbox for the given weapon / attack index.
## Bypasses the handle enabled flag — teardown must always be allowed.
func deactivate_attack(weapon_index: int, attack_index: int) -> void:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    # Use direct array access here — teardown bypasses handle.get_module() enabled guard.
    if attack_index < 0 or attack_index >= handle.attack_modules.size():
        return

    var module: Variant = handle.attack_modules[attack_index]
    if module is AttachedAttackModule:
        (module as AttachedAttackModule).deactivate_attack()


# -------------------------
# Weapon enable / disable
# -------------------------


## Enable or disable an entire weapon.
## This gates future perform_attack / activate_attack calls on all modules
## in this weapon. It does NOT touch any currently live attached hitboxes —
## use deactivate_attack() explicitly before disabling if immediate teardown
## is needed.
func set_weapon_enabled(weapon_index: int, value: bool) -> void:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return

    handle.enabled = value

    for module in handle.attack_modules:
        if module is AttachedAttackModule:
            (module as AttachedAttackModule).enabled = value


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
## Does not mutate the WeaponData or AttackDefinition resource.
## Pass a negative value to effectively disable range checks (e.g. god mode).
func set_attack_range_override(weapon_index: int, attack_index: int, range_value: float) -> void:
    _range_overrides[_range_key(weapon_index, attack_index)] = range_value


## Remove the override for one weapon/attack, restoring its base AttackDefinition range.
func clear_attack_range_override(weapon_index: int, attack_index: int) -> void:
    _range_overrides.erase(_range_key(weapon_index, attack_index))


## Remove all range overrides, restoring all base AttackDefinition ranges.
func clear_all_range_overrides() -> void:
    _range_overrides.clear()


func get_attack_origin() -> Vector2:
    return global_position


# -------------------------
# Internal
# -------------------------


func _range_key(weapon_index: int, attack_index: int) -> String:
    return "%d_%d" % [weapon_index, attack_index]


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
