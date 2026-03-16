class_name CombatModule
extends Node2D

@export var stats: Stats

@export_group("Fire Executors")
@export var melee_attack: MeleeAttackModule
@export var projectile_attack: ProjectileAttackModule

@export_group("Persistent Executors")
@export var contact_attack: ContactAttackModule
@export var charge_attack: ChargeAttackModule

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if not melee_attack:
        melee_attack = find_child("MeleeAttackModule", true, false)

    if not projectile_attack:
        projectile_attack = find_child("ProjectileAttackModule", true, false)

    if not contact_attack:
        contact_attack = find_child("ContactAttackModule", true, false)

    if not charge_attack:
        charge_attack = find_child("ChargeAttackModule", true, false)


# -------------------------
# Fire-and-forget API
# -------------------------


## Execute a one-shot attack toward target_position.
## auto_end=true starts the cooldown immediately.
## Pass auto_end=false and call end_attack(slot) from an animation_finished
## signal to defer the cooldown until the animation completes.
func perform_attack(slot: Stats.AttackSlot, target_position: Vector2, auto_end: bool = true) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var attack_range := get_attack_range(slot)
    if attack_range <= 0.0:
        return

    var distance := global_position.distance_to(target_position)
    if distance > attack_range + 0.01:
        Debug.warn("CombatModule: target out of range. (%s > %s)" % [distance, attack_range])

        var dir := (target_position - global_position).normalized()
        target_position = global_position + dir * attack_range

    var data := _build_attack_data(slot, target_position)
    if data == null:
        return

    var executor := _get_fire_executor_for(data.delivery_type)
    if executor == null:
        push_error("CombatModule: no fire executor for delivery_type %s" % data.delivery_type)
        return

    if not executor.can_attack():
        return

    executor.execute_attack(target_position, data)

    if auto_end:
        executor.end_attack()


## Start the cooldown for a slot's fire executor.
## Call this from an animation_finished signal when using auto_end=false.
func end_attack(slot: Stats.AttackSlot) -> void:
    var executor := _get_fire_executor_for(_get_delivery_type(slot))
    if executor:
        executor.end_attack()


# -------------------------
# Persistent API
# -------------------------


## Enable the persistent hitbox for the given slot.
## direction is used by ChargeAttackModule to orient the front-face hitbox.
## Ignored by ContactAttackModule.
func activate_attack(slot: Stats.AttackSlot, direction: Vector2 = Vector2.RIGHT) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var data := _build_attack_data(slot, global_position + direction)
    if data == null:
        return

    var executor := _get_persistent_executor_for(data.delivery_type)
    if executor == null:
        push_error("CombatModule: no persistent executor for delivery_type %s" % data.delivery_type)
        return

    if executor is ChargeAttackModule:
        executor.facing_direction = direction

    executor.activate_attack(data)


## Disable the persistent hitbox for the given slot.
func deactivate_attack(slot: Stats.AttackSlot) -> void:
    var executor := _get_persistent_executor_for(_get_delivery_type(slot))
    if executor:
        executor.deactivate_attack()


# -------------------------
# Common API
# -------------------------


func get_attack_range(slot: Stats.AttackSlot) -> float:
    if stats == null:
        return 0.0

    match slot:
        Stats.AttackSlot.PRIMARY:
            return stats.primary_attack_range
        Stats.AttackSlot.SECONDARY:
            return stats.secondary_attack_range
        _:
            return 0.0


func get_attack_origin() -> Vector2:
    return global_position


# -------------------------
# Internal Helpers
# -------------------------


func _get_delivery_type(slot: Stats.AttackSlot) -> int:
    if stats == null:
        return -1

    match slot:
        Stats.AttackSlot.PRIMARY:
            return stats.primary_delivery_type
        Stats.AttackSlot.SECONDARY:
            return stats.secondary_delivery_type
        _:
            return -1


func _get_fire_executor_for(delivery_type: int) -> FireAttackModule:
    match delivery_type:
        AttackData.DeliveryType.MELEE:
            return melee_attack
        AttackData.DeliveryType.PROJECTILE:
            return projectile_attack
        _:
            return null


func _get_persistent_executor_for(delivery_type: int) -> PersistentAttackModule:
    match delivery_type:
        AttackData.DeliveryType.CONTACT:
            return contact_attack
        AttackData.DeliveryType.CHARGE:
            return charge_attack
        _:
            return null


func _build_attack_data(slot: Stats.AttackSlot, target_position: Vector2) -> AttackData:
    var data := AttackData.new()
    data.slot = slot
    data.source_position = global_position
    data.target_factions = _build_target_factions()

    var damage_multiplier := 1.0
    var damage_variance := 0.0
    var crit_bonus := 0.0
    var attack_scene: PackedScene = null

    match slot:
        Stats.AttackSlot.PRIMARY:
            data.delivery_type = stats.primary_delivery_type
            attack_scene = stats.primary_attack_scene
            damage_multiplier = stats.primary_damage_multiplier
            damage_variance = stats.primary_damage_variance
            crit_bonus = stats.primary_crit_bonus
            data.knockback_force = stats.primary_knockback
            data.attack_lifetime = stats.primary_lifetime
            data.max_targets = stats.primary_max_targets

        Stats.AttackSlot.SECONDARY:
            data.delivery_type = stats.secondary_delivery_type
            attack_scene = stats.secondary_attack_scene
            damage_multiplier = stats.secondary_damage_multiplier
            damage_variance = stats.secondary_damage_variance
            crit_bonus = stats.secondary_crit_bonus
            data.knockback_force = stats.secondary_knockback
            data.attack_lifetime = stats.secondary_lifetime
            data.max_targets = stats.secondary_max_targets

        _:
            push_warning("CombatModule: unsupported attack slot %s" % slot)
            return null

    # attack_scene is only required for fire-and-forget delivery types.
    # Contact and Charge manage their own hitboxes — no scene needed.
    var needs_attack_scene := data.delivery_type == AttackData.DeliveryType.MELEE or data.delivery_type == AttackData.DeliveryType.PROJECTILE

    if needs_attack_scene and attack_scene == null:
        push_warning("CombatModule: no attack_scene set for slot %s" % slot)
        return null

    data.attack_scene = attack_scene
    data.base_damage = stats.current_damage * damage_multiplier
    data.rolled_damage = _roll_damage(data.base_damage, damage_variance)
    data.is_crit = _roll_crit(stats.current_crit_chance + crit_bonus)
    data.final_damage = data.rolled_damage

    if data.is_crit:
        data.final_damage *= stats.current_crit_multiplier

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


func _roll_damage(base_damage: float, variance: float) -> float:
    variance = max(variance, 0.0)
    if variance <= 0.0:
        return base_damage

    var min_mul := 1.0 - variance
    var max_mul := 1.0 + variance
    return base_damage * randf_range(min_mul, max_mul)


func _roll_crit(chance: float) -> bool:
    chance = clamp(chance, 0.0, 1.0)
    return randf() < chance
