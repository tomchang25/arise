class_name Stats
extends Resource

signal health_changed(health: float)
signal health_depleted

enum BuffableStat { MAX_HEALTH, DAMAGE, DEFENSE, SPEED }
enum Faction { PLAYER, ENEMY }

const BASE_LEVEL_XP: float = 100.0
const BASE_LEVEL_XP_INCREMENT_PER_LEVEL: float = 50.0

@export var base_max_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_defense: float = 10.0
@export var base_speed: float = 1.0

@export var experience: float = 0.0:
    set = _on_experience_set

var health: float = 100.0:
    set = _on_health_set

var faction: Faction

var level: int:
    get:
        return _get_level_from_xp(experience)
var current_max_health: float = 100.0
var current_damage: float = 10.0
var current_defense: float = 10.0
var current_speed: float = 1.0


func _init():
    setup_stats()


func setup_stats():
    recalculate_stats()
    health = current_max_health


func recalculate_stats():
    current_max_health = base_max_health + (level * 10)
    current_damage = base_damage + (level * 2)
    current_defense = base_defense + (level * 2)
    current_speed = base_speed + (level * 0.1)


func take_damage(damage: float):
    health -= damage


func get_xp_required_for_level(lvl: int) -> float:
    if lvl <= 1:
        return 0.0
    # Quadratic scaling: makes the gap wider at higher levels
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
