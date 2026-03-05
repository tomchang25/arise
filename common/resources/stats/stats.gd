@tool
class_name Stats
extends Resource

signal health_changed(health: float)
signal health_depleted
signal stats_recalculated

enum BuffableStat { MAX_HEALTH, DAMAGE, DEFENSE, SPEED }
enum Faction { PLAYER, ENEMY, NEUTRAL }

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

@export var experience: float = 0.0:
    set = _on_experience_set

@export_group("Combat")
@export var invuln_time: float = 0.08

var level: int:
    get:
        return _get_level_from_xp(experience)

var current_max_health: float = 0.0
var current_damage: float = 0.0
var current_defense: float = 0.0
var current_speed: float = 0.0


func _init():
    setup_stats()


func setup_stats():
    recalculate_stats()
    health = current_max_health
    # print_debug("Stats: health %s, current_max_health %s" % [health, current_max_health])


func recalculate_stats():
    current_max_health = base_max_health + ((level - 1) * 10)
    current_damage = base_damage + ((level - 1) * 2)
    current_defense = base_defense + ((level - 1) * 2)
    current_speed = base_speed + ((level - 1) * 0.1)

    health = clamp(health, 0.0, current_max_health)

    stats_recalculated.emit()


func take_damage(damage: float):
    health -= damage


func get_xp_required_for_level(lvl: int) -> float:
    if lvl <= 1:
        return 0.0

    return BASE_LEVEL_XP + (BASE_LEVEL_XP_INCREMENT_PER_LEVEL * pow(lvl - 1, 2))


func _get_level_from_xp(total_xp: float) -> int:
    var estimated_lvl = 1
    while total_xp >= get_xp_required_for_level(estimated_lvl + 1):
        estimated_lvl += 1
    return estimated_lvl


func _on_health_set(new_value: float):
    health = clamp(new_value, 0.0, current_max_health)
    health_changed.emit(health)
    if health <= 0.0:
        health_depleted.emit()


func _on_experience_set(new_value: float):
    var old_level = level
    experience = new_value
    if level != old_level:
        recalculate_stats()
