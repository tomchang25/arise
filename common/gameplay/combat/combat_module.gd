class_name CombatModule
extends Node2D
## Manages all weapons on an actor.
##
## Setup (initialization):
##   Call setup(stats, weapons) once — this is the only correct way to initialize.
##   Assigning .stats directly is blocked and will push an error.
##
##   Has weapons:
##     combat_module.setup(stats, data.weapons)
##
##   No weapons (intentional):
##     combat_module.setup(stats, [])
##
## Hitbox slots (ATTACHED attacks only):
##   Assign `hitbox_slots` before calling setup().
##   Each AttachedAttackDefinition binds by hitbox_slot_id — order in the array
##   does not matter.
##
## Runtime weapon swap:
##   Use equip_weapons(weapons) after setup() to hot-swap weapons mid-game.
##   setup() must have been called first.
##
## API (weapon_index = index in weapons array, attack_index = index in weapon.attacks):
##
##   Unified attack (works for both detached and attached):
##     perform_attack(weapon_index, attack_index, target_position)
##     end_attack(weapon_index, attack_index)
##     can_attack(weapon_index, attack_index) -> bool
##
##   For attached attacks:
##     perform_attack → activates the hitbox   (target_position ignored)
##     end_attack     → deactivates the hitbox
##
##   Weapon switch:
##     set_weapon_enabled(weapon_index, enabled)
##
##   Range overrides (god mode, buffs, debuffs):
##     set_attack_range_override(weapon_index, attack_index, value)
##     clear_attack_range_override(weapon_index, attack_index)
##     clear_all_range_overrides()
##     get_attack_range(weapon_index, attack_index) -> float

@export_group("Hitbox Slots")
## Pre-authored Hitbox nodes for ATTACHED attacks.
## Order does not matter — each AttachedAttackDefinition binds by hitbox_slot_id.
@export var hitbox_slots: Array[Hitbox] = []

# -------------------------
# Stats — access via setup() only
# -------------------------

## Backing variable. Never assign _stats directly from outside this class.
var _stats: Stats

## Read-only access to stats after setup().
## Assigning .stats directly is an error — use setup() instead.
var stats: Stats:
    get:
        return _stats
    set(_value):
        push_error("CombatModule: do not assign .stats directly. Use setup(stats, weapons) instead.")

# -------------------------
# Runtime state
# -------------------------

## WeaponData in use — populated by setup() or equip_weapons().
var _weapons: Array[WeaponData] = []
## WeaponHandle instances, index-matched to _weapons.
var _handles: Array[WeaponHandle] = []
## Range overrides keyed by "wi_ai" string (weapon_index + attack_index).
## When a key exists, get_attack_range() returns its value instead of the
## AttackDefinition base. Does NOT mutate weapon resources.
var _range_overrides: Dictionary = { }

# -------------------------
# Initialization
# -------------------------


## Initialize the module. Must be called before any attack API is used.
##
## Passing an empty weapons array is valid and intentional — write setup(stats, [])
## to make it explicit that this actor has no weapons.
##
## Passing weapons here is preferred over calling equip_weapons() separately,
## as it guarantees stats and weapons are always set together.
func setup(owner_stats: Stats, weapons: Array[WeaponData]) -> void:
    if owner_stats == null:
        push_error("CombatModule: setup() called with null stats.")
        return

    _stats = owner_stats

    if weapons.is_empty():
        _clear_handles()
        return

    _load_weapons(weapons)
    _rebuild_handles()

# -------------------------
# Runtime weapon swap
# -------------------------


## Hot-swap weapons after the module is already initialized.
## setup() must have been called first — stats must already be set.
##
## Duplicates each entry so runtime overrides don't bleed back into source resources.
func equip_weapons(source_weapons: Array[WeaponData]) -> void:
    if _stats == null:
        push_error("CombatModule: equip_weapons() called before setup(). Call setup(stats, weapons) first.")
        return

    _load_weapons(source_weapons)
    _rebuild_handles()

# -------------------------
# Attack API
# -------------------------


## Execute an attack for any module type.
##
## Detached (Projectile, Place, Trap):
##   Fires once toward target_position.
##   Pass auto_end=false and call end_attack() from animation_finished to defer cooldown.
##
## Attached (persistent hitbox):
##   Activates the hitbox. target_position is ignored.
##   Call end_attack() to deactivate.
func perform_attack(weapon_index: int, attack_index: int, target_position: Vector2 = Vector2.ZERO) -> void:
    if _stats == null:
        push_error("CombatModule: perform_attack() called before setup().")
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
            # push_warning("CombatModule: target out of range (%.1f > %.1f)" % [distance, effective_range])
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


func reset() -> void:
    _range_overrides.clear()
    for handle in _handles:
        if handle == null:
            continue
        handle.enabled = true
        for module in handle.attack_modules:
            if module != null:
                module.reset()


func set_enabled(value: bool) -> void:
    for handle in _handles:
        if handle == null:
            continue
        for module in handle.attack_modules:
            if module != null:
                module.enabled = value


func is_enabled() -> bool:
    for handle in _handles:
        if handle == null:
            continue
        for module in handle.attack_modules:
            if module != null and module.enabled:
                return true
    return false


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


## Returns the AttackDefinition at the given weapon / attack slot, or null.
## Provides states a clean path to read definition fields (e.g. prepare_animation,
## locks_movement) without accessing WeaponHandle internals directly.
func get_attack_def(weapon_index: int, attack_index: int = 0) -> AttackDefinition:
    var handle := _get_handle(weapon_index)
    if handle == null:
        return null
    return handle.get_def(attack_index)


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
# Weapon / attack count queries
# -------------------------


## Returns the number of weapons currently equipped.
## Use this to iterate weapons without accessing _weapons directly.
## Example: for wi in combat_module.get_weapon_count()
func get_weapon_count() -> int:
    return _weapons.size()


## Returns the number of attacks on a given weapon.
## Use this alongside get_weapon_count() to iterate all attacks.
## Example: for ai in combat_module.get_attack_count(wi)
func get_attack_count(weapon_index: int) -> int:
    if weapon_index < 0 or weapon_index >= _weapons.size():
        return 0
    return _weapons[weapon_index].attacks.size()

# -------------------------
# Internal
# -------------------------


func _load_weapons(source_weapons: Array[WeaponData]) -> void:
    _weapons.clear()
    for weapon in source_weapons:
        if weapon != null:
            _weapons.append(weapon.duplicate() as WeaponData)


func _rebuild_handles() -> void:
    _clear_handles()
    for weapon in _weapons:
        var handle := WeaponExecutor.build(weapon, self, hitbox_slots, _stats)
        _handles.append(handle)


func _get_handle(weapon_index: int) -> WeaponHandle:
    if weapon_index < 0 or weapon_index >= _handles.size():
        push_warning("CombatModule: %s weapon_index %d out of range" % [owner.name, weapon_index])
        return null
    return _handles[weapon_index]


func _clear_handles() -> void:
    for handle in _handles:
        if handle != null:
            handle.teardown()
    _handles.clear()


func _range_key(weapon_index: int, attack_index: int) -> String:
    return "%d_%d" % [weapon_index, attack_index]
