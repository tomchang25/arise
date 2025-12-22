@tool
class_name EnemyScanner
extends Node2D

@export var detectbox_radius: float = 150.0:
    set(value):
        detectbox_radius = value
        if is_node_ready() and detectbox:
            detectbox.radius = detectbox_radius

@export var visible_range: float = 100.0
@export var attack_range: float = 50.0

var detectbox: Detectbox

var _all_enemies: Array = []


func _ready() -> void:
    _setup_detectbox()


func _setup_detectbox() -> void:
    for child in get_children():
        if child is Detectbox:
            detectbox = child

    detectbox.radius = detectbox_radius
    detectbox.targets_changed.connect(_on_targets_changed)


func _on_targets_changed(nodes: Array) -> void:
    _all_enemies = nodes.filter(func(node): return node.get_owner() is Enemy)


# --- Visibility Methods ---


func get_enemies_visible() -> Array:
    return _all_enemies.filter(func(e): return global_position.distance_to(e.global_position) <= visible_range)


func is_enemy_visible() -> bool:
    return not get_enemies_visible().is_empty()


func get_nearest_visible_enemy() -> Node2D:
    return _get_closest(get_enemies_visible())


# --- Attackable Methods ---


func get_enemies_attackable() -> Array:
    return _all_enemies.filter(func(e): return global_position.distance_to(e.global_position) <= attack_range)


func is_enemy_attackable() -> bool:
    return not get_enemies_attackable().is_empty()


func get_nearest_attackable_enemy() -> Node2D:
    return _get_closest(get_enemies_attackable())


# --- Private Helper ---


func _get_closest(list: Array) -> Node2D:
    var nearest: Node2D = null
    var min_dist: float = INF

    for enemy in list:
        var dist = global_position.distance_to(enemy.global_position)
        if dist < min_dist:
            min_dist = dist
            nearest = enemy
    return nearest
