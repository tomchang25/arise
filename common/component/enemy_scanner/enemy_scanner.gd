@tool
class_name EnemyScanner
extends Node2D

@export var visible_range: float = 100.0:
    set(value):
        visible_range = value
        if is_node_ready() and detectbox:
            update_detectbox()

@export var attack_range: float = 50.0:
    set(value):
        attack_range = value
        if is_node_ready() and detectbox:
            update_detectbox()

@export var use_external: bool = false

var detectbox: Detectbox

var _internal_enemies: Array = []
var _external_enemies: Array = []


func _ready() -> void:
    _setup_detectbox()


func _setup_detectbox() -> void:
    for child in get_children():
        if child is Detectbox:
            detectbox = child

    detectbox.targets_changed.connect(_on_targets_changed)
    update_detectbox()


func _on_targets_changed(nodes: Array) -> void:
    _internal_enemies = nodes


# --- Technical ---


func update_detectbox() -> void:
    var max_range = max(visible_range, attack_range)

    detectbox.radius = max_range


func set_external_enemies(enemies: Array) -> void:
    _external_enemies = enemies
    use_external = true


func get_internal_enemies() -> Array:
    return _internal_enemies


# --- Generic Range Detection ---


func get_enemies_in_range(range_distance: float) -> Array:
    return get_internal_enemies().filter(func(e): return global_position.distance_to(e.global_position) <= range_distance)


func get_nearest_in_range(range_distance: float) -> Node2D:
    return _get_closest(get_enemies_in_range(range_distance))


# --- Tracked Methods ---


func get_enemies_tracked() -> Array:
    if use_external:
        return _external_enemies

    return get_enemies_visible()


func is_enemy_tracked() -> bool:
    return not get_enemies_tracked().is_empty()


func get_nearest_tracked_enemy() -> Node2D:
    return _get_closest(get_enemies_tracked())


# TODO: REOVE ALL OF THIS EXCEPT _get_closest
# --- Visibility Methods ---


func get_enemies_visible() -> Array:
    return get_internal_enemies().filter(func(e): return global_position.distance_to(e.global_position) <= visible_range)


func is_enemy_visible() -> bool:
    return not get_enemies_visible().is_empty()


func get_nearest_visible_enemy() -> Node2D:
    return _get_closest(get_enemies_visible())


# --- Attackable Methods ---


func get_enemies_attackable() -> Array:
    return get_internal_enemies().filter(func(e): return global_position.distance_to(e.global_position) <= attack_range)


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
