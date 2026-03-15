@tool
class_name Stats
extends Resource

signal health_changed(health: float)
signal mana_changed(mana: float)
signal souls_changed(souls: int)
signal gold_changed(gold: int)
signal health_depleted
signal stats_recalculated

enum BuffableStat { MAX_HEALTH, MAX_MANA, DAMAGE, DEFENSE, SPEED }
enum Faction { PLAYER, ENEMY, NEUTRAL }
enum AttackSlot { PRIMARY, SECONDARY, SKILL_1, SKILL_2 }

const BASE_LEVEL_XP: float = 100.0
const BASE_LEVEL_XP_INCREMENT_PER_LEVEL: float = 50.0

@export var faction: Faction

@export_group("Runtime Resources")
@export var health: float = 100.0:
    set = _on_health_set

@export var mana: float = 0.0:
    set = _on_mana_set

@export var souls: int = 0:
    set = _on_souls_set

@export var gold: int = 0:
    set = _on_gold_set

@export_group("Base Stats")
@export var base_max_health: float = 100.0:
    set(value):
        base_max_health = value
        recalculate_stats()

@export var base_max_mana: float = 100.0:
    set(value):
        base_max_mana = value
        recalculate_stats()

@export var base_damage: float = 10.0:
    set(value):
        base_damage = value
        recalculate_stats()

@export var base_defense: float = 10.0:
    set(value):
        base_defense = value
        recalculate_stats()

@export var base_speed: float = 1.0:
    set(value):
        base_speed = value
        recalculate_stats()

@export_group("Crit")
@export_range(0.0, 1.0, 0.01) var base_crit_chance: float = 0.05:
    set(value):
        base_crit_chance = value
        recalculate_stats()

@export var base_crit_multiplier: float = 1.5:
    set(value):
        base_crit_multiplier = value
        recalculate_stats()

@export_group("Weapon Layer (temporary merged)")
@export var weapon_damage: float = 0.0:
    set(value):
        weapon_damage = value
        recalculate_stats()

@export_range(0.0, 1.0, 0.01) var weapon_crit_chance: float = 0.0:
    set(value):
        weapon_crit_chance = value
        recalculate_stats()

@export var weapon_crit_multiplier: float = 0.0:
    set(value):
        weapon_crit_multiplier = value
        recalculate_stats()

@export_group("Primary Attack")
@export var primary_delivery_type: AttackData.DeliveryType = AttackData.DeliveryType.MELEE
@export var primary_attack_scene: PackedScene = null
@export var primary_attack_range: float = 30.0:
    set(value):
        primary_attack_range = value
        recalculate_stats()

@export var primary_damage_multiplier: float = 1.0
@export_range(0.0, 4.0, 0.01) var primary_damage_variance: float = 0.10
@export_range(0.0, 4.0, 0.01) var primary_crit_bonus: float = 0.0
@export var primary_knockback: float = 40.0
@export var primary_lifetime: float = 0.20
@export var primary_max_targets: int = 1

@export_group("Secondary Attack")
@export var secondary_delivery_type: AttackData.DeliveryType = AttackData.DeliveryType.MELEE
@export var secondary_attack_scene: PackedScene = null
@export var secondary_attack_range: float = 60.0:
    set(value):
        secondary_attack_range = value
        recalculate_stats()

@export var secondary_damage_multiplier: float = 1.8
@export_range(0.0, 4.0, 0.01) var secondary_damage_variance: float = 0.15
@export_range(0.0, 4.0, 0.01) var secondary_crit_bonus: float = 0.05
@export var secondary_knockback: float = 100.0
@export var secondary_lifetime: float = 0.25
@export var secondary_max_targets: int = 2

@export_group("Combat")
@export var invuln_time: float = 0.08

@export_group("XP")
@export var experience: float = 0.0:
    set = _on_experience_set

var level: int:
    get:
        return _get_level_from_xp(experience)

var current_max_health: float = 0.0
var current_max_mana: float = 0.0
var current_damage: float = 0.0
var current_defense: float = 0.0
var current_speed: float = 0.0
var current_crit_chance: float = 0.0
var current_crit_multiplier: float = 1.5


func _init() -> void:
    setup_stats()


# -------------------------
# Lifecycle
# -------------------------


func setup_stats() -> void:
    recalculate_stats()
    health = current_max_health
    mana = current_max_mana
    souls = max(0, souls)
    gold = max(0, gold)


# -------------------------
# Stats Recalculation
# -------------------------


func recalculate_stats() -> void:
    current_max_health = base_max_health + ((level - 1) * 10.0)
    current_max_mana = base_max_mana + ((level - 1) * 5.0)
    current_damage = base_damage + weapon_damage + ((level - 1) * 2.0)
    current_defense = base_defense + ((level - 1) * 2.0)
    current_speed = base_speed + ((level - 1) * 0.1)

    current_crit_chance = clamp(base_crit_chance + weapon_crit_chance, 0.0, 1.0)
    current_crit_multiplier = max(1.0, base_crit_multiplier + weapon_crit_multiplier)

    health = clamp(health, 0.0, current_max_health)
    mana = clamp(mana, 0.0, current_max_mana)
    souls = max(0, souls)
    gold = max(0, gold)

    stats_recalculated.emit()


# -------------------------
# Health
# -------------------------


func can_recover_health(amount: float) -> bool:
    return amount > 0.0 and health < current_max_health


func recover_health(amount: float) -> bool:
    if not can_recover_health(amount):
        return false

    health = min(health + amount, current_max_health)
    return true


func take_damage(damage: float) -> void:
    health -= damage


# -------------------------
# Mana
# -------------------------


func can_add_mana(amount: float) -> bool:
    return amount > 0.0 and mana < current_max_mana


func add_mana(amount: float) -> bool:
    if not can_add_mana(amount):
        return false

    mana = min(mana + amount, current_max_mana)
    return true


func spend_mana(amount: float) -> bool:
    if amount <= 0.0:
        return false
    if mana < amount:
        return false

    mana -= amount
    return true


# -------------------------
# Souls
# -------------------------


func can_add_souls(amount: int) -> bool:
    return amount > 0


func add_souls(amount: int) -> bool:
    if not can_add_souls(amount):
        return false

    souls += amount
    return true


func spend_souls(amount: int) -> bool:
    if amount <= 0:
        return false
    if souls < amount:
        return false

    souls -= amount
    return true


# -------------------------
# Gold
# -------------------------


func can_add_gold(amount: int) -> bool:
    return amount > 0


func add_gold(amount: int) -> bool:
    if not can_add_gold(amount):
        return false

    gold += amount
    return true


func spend_gold(amount: int) -> bool:
    if amount <= 0:
        return false
    if gold < amount:
        return false

    gold -= amount
    return true


# -------------------------
# XP
# -------------------------


func get_xp_required_for_level(lvl: int) -> float:
    if lvl <= 1:
        return 0.0
    return BASE_LEVEL_XP + (BASE_LEVEL_XP_INCREMENT_PER_LEVEL * pow(lvl - 1, 2))


func _get_level_from_xp(total_xp: float) -> int:
    var estimated_lvl := 1
    while total_xp >= get_xp_required_for_level(estimated_lvl + 1):
        estimated_lvl += 1
    return estimated_lvl


# -------------------------
# Debug / Reset
# -------------------------


func reset_runtime_resources(reset_health_value: float = -1.0, reset_mana_value: float = -1.0, reset_souls_value: int = 0, reset_gold_value: int = 0) -> void:
    if reset_health_value < 0.0:
        health = current_max_health
    else:
        health = clamp(reset_health_value, 0.0, current_max_health)

    if reset_mana_value < 0.0:
        mana = current_max_mana
    else:
        mana = clamp(reset_mana_value, 0.0, current_max_mana)

    souls = max(0, reset_souls_value)
    gold = max(0, reset_gold_value)


# -------------------------
# Property Setters
# -------------------------


func _on_health_set(new_value: float) -> void:
    health = clamp(new_value, 0.0, current_max_health)
    health_changed.emit(health)
    if health <= 0.0:
        health_depleted.emit()


func _on_mana_set(new_value: float) -> void:
    mana = clamp(new_value, 0.0, current_max_mana)
    mana_changed.emit(mana)


func _on_souls_set(new_value: int) -> void:
    souls = max(0, new_value)
    souls_changed.emit(souls)


func _on_gold_set(new_value: int) -> void:
    gold = max(0, new_value)
    gold_changed.emit(gold)


func _on_experience_set(new_value: float) -> void:
    var old_level := level
    experience = new_value
    if level != old_level:
        recalculate_stats()
