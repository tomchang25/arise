@tool
class_name Stats
extends Resource

signal health_changed(health: float)
signal health_depleted
signal stats_recalculated

enum BuffableStat { MAX_HEALTH, DAMAGE, DEFENSE, SPEED }
enum Faction { PLAYER, ENEMY, NEUTRAL }
enum AttackSlot { PRIMARY, SECONDARY, SKILL_1, SKILL_2 }

const BASE_LEVEL_XP: float = 100.0
const BASE_LEVEL_XP_INCREMENT_PER_LEVEL: float = 50.0

@export var faction: Faction

@export var health: float = 100.0:
    set = _on_health_set

@export_group("Base Stats")
@export var base_max_health: float = 100.0:
    set(value):
        base_max_health = value
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
@export var primary_delivery_type: AttackInfo.DeliveryType = AttackInfo.DeliveryType.MELEE
@export var primary_effect_scene: PackedScene = null
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
@export var secondary_delivery_type: AttackInfo.DeliveryType = AttackInfo.DeliveryType.MELEE
@export var secondary_effect_scene: PackedScene = null
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
var current_damage: float = 0.0
var current_defense: float = 0.0
var current_speed: float = 0.0
var current_crit_chance: float = 0.0
var current_crit_multiplier: float = 1.5


func _init():
    setup_stats()


func setup_stats() -> void:
    recalculate_stats()
    health = current_max_health


func recalculate_stats() -> void:
    current_max_health = base_max_health + ((level - 1) * 10)
    current_damage = base_damage + weapon_damage + ((level - 1) * 2)
    current_defense = base_defense + ((level - 1) * 2)
    current_speed = base_speed + ((level - 1) * 0.1)

    current_crit_chance = clamp(base_crit_chance + weapon_crit_chance, 0.0, 1.0)
    current_crit_multiplier = max(1.0, base_crit_multiplier + weapon_crit_multiplier)

    health = clamp(health, 0.0, current_max_health)
    stats_recalculated.emit()


func take_damage(damage: float) -> void:
    health -= damage


func get_xp_required_for_level(lvl: int) -> float:
    if lvl <= 1:
        return 0.0
    return BASE_LEVEL_XP + (BASE_LEVEL_XP_INCREMENT_PER_LEVEL * pow(lvl - 1, 2))


func _get_level_from_xp(total_xp: float) -> int:
    var estimated_lvl := 1
    while total_xp >= get_xp_required_for_level(estimated_lvl + 1):
        estimated_lvl += 1
    return estimated_lvl


func _on_health_set(new_value: float) -> void:
    health = clamp(new_value, 0.0, current_max_health)
    health_changed.emit(health)
    if health <= 0.0:
        health_depleted.emit()


func _on_experience_set(new_value: float) -> void:
    var old_level := level
    experience = new_value
    if level != old_level:
        recalculate_stats()
