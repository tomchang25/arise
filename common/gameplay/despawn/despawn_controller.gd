class_name DespawnController
extends Node2D

@export var enabled: bool = true

@export_group("Tracking")
@export var tracked_target: Node2D

@export_group("Distance Despawn")
@export var use_distance_limit: bool = true
@export var despawn_distance: float = 480.0

@export_group("Bounds Despawn")
@export var use_play_area_rect: bool = false
@export var play_area_rect: Rect2

@export_group("Runtime")
@export var cleanup_interval: float = 0.25

@export_group("Debug")
@export var draw_debug: bool = false:
    set(value):
        draw_debug = value
        queue_redraw()

var _spawn_registry := SpawnRegistry.new()
var _timer: float = 0.0


func _ready() -> void:
    if use_distance_limit and tracked_target == null:
        Debug.warn("DespawnController: use_distance_limit is true but tracked_target is not assigned")


func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return

    if not enabled:
        return

    _timer += delta
    if _timer < cleanup_interval:
        return

    _timer = 0.0
    _cleanup_invalid_entries()
    _despawn_outside_rules()

    if draw_debug:
        queue_redraw()


func _draw() -> void:
    if not draw_debug:
        return

    var center := _get_draw_center()

    if use_distance_limit and despawn_distance > 0.0:
        draw_arc(center, despawn_distance, 0.0, TAU, 128, Color(1.0, 0.3, 0.1, 0.8), 2.0)

        # Label-style tick at top so it's readable without overlapping the circle
        var label_pos := center + Vector2(0.0, -despawn_distance - 16.0)
        draw_string(ThemeDB.fallback_font, label_pos, "despawn: %.0f" % despawn_distance, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1.0, 0.3, 0.1, 0.9))

    if use_play_area_rect:
        draw_rect(Rect2(to_local(play_area_rect.position), play_area_rect.size), Color(0.2, 0.6, 1.0, 0.8), false, 2.0)


# -------------------------
# Public API
# -------------------------


func register_spawned(node: Node) -> void:
    var node_2d := node as Node2D
    if node_2d == null:
        return

    _spawn_registry.register_node(node_2d)


func unregister_spawned(node: Node) -> void:
    _spawn_registry.unregister_node(node)


func clear_all() -> void:
    _spawn_registry.clear()


# -------------------------
# Internal
# -------------------------


func _cleanup_invalid_entries() -> void:
    _spawn_registry.cleanup_invalid()


func _despawn_outside_rules() -> void:
    for node in _spawn_registry.get_valid_nodes_2d():
        if not is_instance_valid(node):
            continue

        if _should_despawn(node):
            node.queue_free()


func _should_despawn(node: Node2D) -> bool:
    if use_distance_limit and tracked_target != null:
        if node.global_position.distance_to(tracked_target.global_position) > despawn_distance:
            return true

    if use_play_area_rect and not play_area_rect.has_point(node.global_position):
        return true

    return false


func _get_draw_center() -> Vector2:
    if tracked_target != null and is_instance_valid(tracked_target):
        return to_local(tracked_target.global_position)
    return Vector2.ZERO
