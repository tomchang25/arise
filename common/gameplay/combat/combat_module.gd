class_name CombatModule
extends Node2D

## Manages all weapons on an actor.
##
## Setup:
##   1. Assign `stats` (actor's Stats resource).
##   2. Assign `hitbox_slots` (pre-authored Hitbox nodes in the scene) for any
##      CONTACT or CHARGE weapons. Fire-and-forget types need no hitbox slots.
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
##   Persistent:
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
## Pre-authored Hitbox nodes for CONTACT and CHARGE attacks.
## Assigned in order as persistent weapons are set up.
## Add as many as the actor has persistent attack types.
@export var hitbox_slots: Array[Hitbox] = []

# -------------------------
# Runtime state
# -------------------------

## WeaponExecutor instances, index-matched to `weapons`.
var _weapon_executors: Array[WeaponExecutor] = []

## Next hitbox slot to claim for a persistent executor.
var _next_hitbox_slot: int = 0

## Range overrides keyed by "_wi_ai" string (weapon_index + attack_index).
## When a key exists, get_attack_range() returns its value instead of the
## AttackDefinition base. Does NOT mutate weapon resources.
var _range_overrides: Dictionary = {}

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    setup()


## Build all WeaponExecutors from the current `weapons` array.
## Safe to call again if weapons change at runtime (clears and rebuilds).
func setup() -> void:
    _clear_executors()
    _next_hitbox_slot = 0

    for i in weapons.size():
        _build_executor(i, weapons[i])


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

    var executor := _get_weapon_executor(weapon_index)
    if executor == null or not executor.enabled:
        return

    var atk_executor := _get_attack_executor(executor, attack_index)
    if atk_executor == null:
        return

    var fire := atk_executor as FireAttackModule
    if fire == null:
        push_error("CombatModule: perform_attack called on a persistent executor (weapon %d, attack %d)" % [weapon_index, attack_index])
        return

    if not fire.can_attack():
        return

    var effective_range := get_attack_range(weapon_index, attack_index)
    var distance := global_position.distance_to(target_position)
    if distance > effective_range + 0.01:
        Debug.warn("CombatModule: target out of range (%.1f > %.1f)" % [distance, effective_range])
        var dir := (target_position - global_position).normalized()
        target_position = global_position + dir * effective_range

    var def := executor.weapon.attacks[attack_index] as AttackDefinition
    var data := _build_attack_data(def, target_position)
    if data == null:
        return

    fire.execute_attack(target_position, data)

    if auto_end:
        fire.end_attack()


## Start the cooldown for a fire executor.
## Call from animation_finished when using auto_end=false.
func end_attack(weapon_index: int, attack_index: int) -> void:
    var executor := _get_weapon_executor(weapon_index)
    if executor == null:
        return

    var atk_executor := _get_attack_executor(executor, attack_index)
    if atk_executor is FireAttackModule:
        (atk_executor as FireAttackModule).end_attack()


## Returns true if the fire executor is ready to attack.
func can_attack(weapon_index: int, attack_index: int) -> bool:
    var executor := _get_weapon_executor(weapon_index)
    if executor == null or not executor.enabled:
        return false

    var atk_executor := _get_attack_executor(executor, attack_index)
    if atk_executor is FireAttackModule:
        return (atk_executor as FireAttackModule).can_attack()

    return false


# -------------------------
# Persistent API
# -------------------------


## Enable the persistent hitbox for the given weapon / attack index.
func activate_attack(weapon_index: int, attack_index: int) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var executor := _get_weapon_executor(weapon_index)
    if executor == null or not executor.enabled:
        return

    var atk_executor := _get_attack_executor(executor, attack_index)
    if atk_executor == null:
        return

    var persistent := atk_executor as PersistentAttackModule
    if persistent == null:
        push_error("CombatModule: activate_attack called on a fire executor (weapon %d, attack %d)" % [weapon_index, attack_index])
        return

    var def := executor.weapon.attacks[attack_index] as AttackDefinition
    var data := _build_attack_data(def)
    if data == null:
        return

    persistent.activate_attack(data)


## Disable the persistent hitbox for the given weapon / attack index.
func deactivate_attack(weapon_index: int, attack_index: int) -> void:
    var executor := _get_weapon_executor(weapon_index)
    if executor == null:
        return

    var atk_executor := _get_attack_executor(executor, attack_index)
    if atk_executor is PersistentAttackModule:
        (atk_executor as PersistentAttackModule).deactivate_attack()


# -------------------------
# Weapon enable / disable
# -------------------------


## Enable or disable an entire weapon.
## Disabling force-deactivates any live persistent hitboxes on that weapon.
func set_weapon_enabled(weapon_index: int, value: bool) -> void:
    var executor := _get_weapon_executor(weapon_index)
    if executor == null:
        return

    executor.enabled = value

    # if not value:
    #     for atk_executor in executor.attack_executors:
    #         if atk_executor is PersistentAttackModule:
    #             (atk_executor as PersistentAttackModule).deactivate_attack()


# -------------------------
# Range override API
# -------------------------


## Returns the effective attack range for the given weapon/attack.
## If a range override is active, that value is returned instead of the
## AttackDefinition base value.
func get_attack_range(weapon_index: int, attack_index: int = 0) -> float:
    var key := _range_key(weapon_index, attack_index)
    if _range_overrides.has(key):
        return _range_overrides[key]

    var executor := _get_weapon_executor(weapon_index)
    if executor == null:
        return 0.0

    if attack_index >= executor.weapon.attacks.size():
        return 0.0

    return executor.weapon.attacks[attack_index].attack_range


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
# Internal — setup helpers
# -------------------------


func _clear_executors() -> void:
    for we in _weapon_executors:
        for atk_exec in we.attack_executors:
            if atk_exec is Node and (atk_exec as Node).is_inside_tree():
                (atk_exec as Node).queue_free()

    _weapon_executors.clear()


func _build_executor(weapon_index: int, weapon: WeaponData) -> void:
    if weapon == null:
        push_warning("CombatModule: null WeaponData at index %d" % weapon_index)
        return

    var we := WeaponExecutor.new()
    we.weapon = weapon

    for i in weapon.attacks.size():
        var def := weapon.attacks[i] as AttackDefinition
        if def == null:
            push_warning("CombatModule: null AttackDefinition at weapon %d, attack %d" % [weapon_index, i])
            we.attack_executors.append(null)
            continue

        var atk_exec := _spawn_executor(def)
        if atk_exec is Node:
            add_child(atk_exec as Node)

        we.attack_executors.append(atk_exec)

    _weapon_executors.append(we)


func _spawn_executor(def: AttackDefinition) -> Object:
    match def.delivery_type:
        AttackData.DeliveryType.MELEE:
            var m := MeleeAttackModule.new()
            m.setup(def.cooldown)
            return m

        AttackData.DeliveryType.PROJECTILE:
            var m := ProjectileAttackModule.new()
            m.setup(def.cooldown, def.projectile_speed)
            return m

        AttackData.DeliveryType.CONTACT:
            # Persistent hitbox — geometry and orientation are owned by AnimationPlayer on the scene.
            var m := ContactAttackModule.new()
            var slot := _claim_hitbox_slot()
            if slot == null:
                push_error("CombatModule: no hitbox slot available for CONTACT attack")
            else:
                m.setup(slot)
            return m

        _:
            push_error("CombatModule: unknown delivery_type %d" % def.delivery_type)
            return null


func _claim_hitbox_slot() -> Hitbox:
    if _next_hitbox_slot >= hitbox_slots.size():
        return null

    var slot := hitbox_slots[_next_hitbox_slot]
    _next_hitbox_slot += 1
    return slot


# -------------------------
# Internal — runtime helpers
# -------------------------


func _range_key(weapon_index: int, attack_index: int) -> String:
    return "%d_%d" % [weapon_index, attack_index]


func _get_weapon_executor(weapon_index: int) -> WeaponExecutor:
    if weapon_index < 0 or weapon_index >= _weapon_executors.size():
        push_warning("CombatModule: weapon_index %d out of range" % weapon_index)
        return null

    return _weapon_executors[weapon_index]


func _get_attack_executor(weapon_executor: WeaponExecutor, attack_index: int) -> Object:
    if attack_index < 0 or attack_index >= weapon_executor.attack_executors.size():
        push_warning("CombatModule: attack_index %d out of range for weapon '%s'" % [attack_index, weapon_executor.weapon.weapon_name])
        return null

    return weapon_executor.attack_executors[attack_index]


## Build AttackData from an AttackDefinition.
## For fire-and-forget types, pass target_position to bake knockback_dir.
## For persistent types (CONTACT), omit target_position — knockback_source
## is set instead so victims compute direction at hit time.
func _build_attack_data(def: AttackDefinition, target_position: Vector2 = Vector2.ZERO) -> AttackData:
    if stats == null:
        push_error("CombatModule: stats is null in _build_attack_data")
        return null

    var data := AttackData.new()
    data.target_factions = _build_target_factions()
    data.delivery_type = def.delivery_type

    var is_persistent := def.delivery_type == AttackData.DeliveryType.CONTACT

    var needs_attack_scene := def.delivery_type == AttackData.DeliveryType.MELEE or def.delivery_type == AttackData.DeliveryType.PROJECTILE

    if needs_attack_scene and def.attack_scene == null:
        push_warning("CombatModule: no attack_scene on AttackDefinition for delivery_type %d" % def.delivery_type)
        return null

    data.attack_scene = def.attack_scene
    data.base_damage = stats.current_damage * def.damage_multiplier
    data.rolled_damage = _roll_damage_variance(data.base_damage, def.damage_variance)
    data.is_crit = _roll_crit(stats.current_crit_chance + def.crit_bonus)
    data.crit_multiplier = stats.current_crit_multiplier

    data.knockback_force = def.knockback
    data.attack_lifetime = def.lifetime
    data.max_targets = def.max_targets

    if is_persistent:
        # Contact attacks don't have a travel direction — victim resolves
        # knockback direction from knockback_source at hit time.
        data.knockback_source = self
    else:
        var dir := target_position - global_position
        if dir.length_squared() <= 0.0001:
            dir = Vector2.RIGHT
        else:
            dir = dir.normalized()
        data.knockback_dir = dir

    return data


func _build_target_factions() -> Array:
    match stats.faction:
        Stats.Faction.PLAYER:
            return [Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]
        Stats.Faction.ENEMY:
            return [Stats.Faction.PLAYER]
        Stats.Faction.NEUTRAL:
            return []
        _:
            return []


## Returns a signed variance offset to add onto base_damage.
## variance is a 0.0–1.0 fraction of base_damage as the max swing.
func _roll_damage_variance(base_damage: float, variance: float) -> float:
    variance = max(variance, 0.0)
    if variance <= 0.0:
        return 0.0

    var max_offset := base_damage * variance
    return randf_range(-max_offset, max_offset)


func _roll_crit(chance: float) -> bool:
    chance = clamp(chance, 0.0, 1.0)
    return randf() < chance
