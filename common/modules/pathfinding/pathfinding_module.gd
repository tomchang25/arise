@tool
class_name PathfindingModule
extends Node2D

signal navigation_finished
signal target_changed(target_position: Vector2)
signal target_lost

@export var enabled := true:
    set(value):
        enabled = value
        if not enabled:
            _stop_runtime_pathing()

@export var character: CharacterBody2D
@export var movement: MovementModule
@export var navigation_agent: NavigationAgent2D

@export_group("Path Update")
@export var target_update_interval := 0.20
@export var repath_distance_threshold := 8.0

@export_group("Movement")
@export var auto_set_path_mode := true
@export var max_speed := 100.0
@export var arrive_distance := 4.0

@export_group("Avoidance")
@export var enable_avoidance := false:
    set(value):
        enable_avoidance = value
        _apply_avoidance_settings()

@export var avoidance_priority := 1.0:
    set(value):
        avoidance_priority = value
        _apply_avoidance_settings()

@export_group("Debug")
@export var debug_print_state := false
@export var debug_disable_navigation_agent := false
@export var debug_draw := true
@export var debug_color_path := Color(0.2, 0.8, 1.0, 0.9)
@export var debug_color_target := Color(1.0, 0.3, 0.3, 0.9)
@export var debug_color_next := Color(0.3, 1.0, 0.3, 0.9)

var _follow_target: Node2D
var _has_target_position := false
var _target_position: Vector2 = Vector2.ZERO
var _last_applied_target_position: Vector2 = Vector2.INF
var _target_update_timer := 0.0
var _finished_emitted := false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _auto_wire()
    _apply_navigation_settings()
    _clear_path_velocity()


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire()
        _apply_navigation_settings()


func _physics_process(delta: float) -> void:
    if not enabled:
        return

    if character == null:
        _clear_path_velocity()
        return

    if not _has_active_target():
        _clear_path_velocity()
        return

    _target_update_timer += delta
    if _target_update_timer >= target_update_interval:
        _target_update_timer = 0.0
        _refresh_target_position()

    if _should_use_fallback_direct_path():
        _fallback_direct_path()
        return

    if navigation_agent.is_navigation_finished():
        _clear_path_velocity()
        _emit_navigation_finished_once()
        return

    _finished_emitted = false

    var next_point := navigation_agent.get_next_path_position()
    var origin := character.global_position
    var desired_velocity := (next_point - origin).normalized() * max_speed

    if navigation_agent.avoidance_enabled:
        navigation_agent.set_velocity(desired_velocity)
    else:
        _apply_path_velocity(desired_velocity)

    if debug_draw:
        queue_redraw()


func _draw() -> void:
    if not debug_draw:
        return

    if character == null:
        return

    var origin := character.global_position

    # Draw target
    if _has_target_position:
        draw_circle(to_local(_target_position), 4, debug_color_target)

        draw_arc(to_local(_target_position), arrive_distance, 0, TAU, 24, debug_color_target, 1.5)

    # Draw path
    if navigation_agent:
        var path := navigation_agent.get_current_navigation_path()

        if path.size() >= 2:
            for i in range(path.size() - 1):
                draw_line(to_local(path[i]), to_local(path[i + 1]), debug_color_path, 2.0)

    # Draw next point
    if navigation_agent and not navigation_agent.is_navigation_finished():
        var next_point := navigation_agent.get_next_path_position()

        draw_circle(to_local(next_point), 3, debug_color_next)

        draw_line(to_local(origin), to_local(next_point), debug_color_next, 1.5)


# -------------------------
# Common API
# -------------------------


func _auto_wire() -> void:
    if character == null:
        character = get_parent() as CharacterBody2D

    if movement == null:
        movement = find_child("MovementModule", true, false) as MovementModule

    if navigation_agent == null:
        navigation_agent = find_child("NavigationAgent2D", true, false) as NavigationAgent2D


func _apply_navigation_settings() -> void:
    if navigation_agent == null:
        return

    navigation_agent.target_desired_distance = arrive_distance
    navigation_agent.max_speed = max_speed

    _apply_avoidance_settings()

    if not navigation_agent.velocity_computed.is_connected(_on_velocity_computed):
        navigation_agent.velocity_computed.connect(_on_velocity_computed)

    if not navigation_agent.navigation_finished.is_connected(_on_navigation_finished):
        navigation_agent.navigation_finished.connect(_on_navigation_finished)


func _apply_avoidance_settings() -> void:
    if navigation_agent == null:
        return

    navigation_agent.avoidance_enabled = enable_avoidance
    navigation_agent.avoidance_priority = avoidance_priority


func _stop_runtime_pathing() -> void:
    clear_target()


func set_enabled(value: bool, clear_target_data: bool = true) -> void:
    enabled = value

    if not enabled and clear_target_data:
        _stop_runtime_pathing()


func is_enabled() -> bool:
    return enabled


func has_target() -> bool:
    return _has_active_target()


func is_path_finished() -> bool:
    if _should_use_fallback_direct_path():
        if not character or not _has_target_position:
            return true
        return character.global_position.distance_to(_target_position) <= arrive_distance

    if navigation_agent:
        return navigation_agent.is_navigation_finished()

    return true


func get_target_position() -> Vector2:
    return _target_position


func get_follow_target() -> Node2D:
    return _follow_target


func set_avoidance_enabled(value: bool) -> void:
    enable_avoidance = value


func is_avoidance_enabled() -> bool:
    return enable_avoidance


func set_avoidance_priority(value: float) -> void:
    avoidance_priority = value


# -------------------------
# Target Control
# -------------------------


func set_target_position(world_position: Vector2) -> void:
    _follow_target = null
    _target_position = world_position
    _has_target_position = true
    _finished_emitted = false
    _target_update_timer = 0.0
    _refresh_target_position()


func follow_target_node(node: Node2D) -> void:
    _follow_target = node
    _has_target_position = node != null
    _finished_emitted = false
    _target_update_timer = 0.0
    _refresh_target_position()


func clear_target() -> void:
    _follow_target = null
    _has_target_position = false
    _target_position = Vector2.ZERO
    _last_applied_target_position = Vector2.INF
    _target_update_timer = 0.0
    _finished_emitted = false

    _clear_path_velocity()

    if navigation_agent and character:
        navigation_agent.target_position = character.global_position
    elif navigation_agent:
        navigation_agent.target_position = Vector2.ZERO


func stop() -> void:
    clear_target()


func stop_path_motion_only() -> void:
    _clear_path_velocity()


# -------------------------
# Runtime Helpers
# -------------------------


func _has_active_target() -> bool:
    if _follow_target and not is_instance_valid(_follow_target):
        _follow_target = null
        _has_target_position = false
        target_lost.emit()
        return false

    return _follow_target != null or _has_target_position


func _refresh_target_position() -> void:
    var next_target := _target_position

    if _follow_target:
        next_target = _follow_target.global_position

    _target_position = next_target
    _has_target_position = true

    if (
        navigation_agent
        and (_last_applied_target_position == Vector2.INF or _last_applied_target_position.distance_to(_target_position) >= repath_distance_threshold)
    ):
        navigation_agent.target_position = _target_position
        _last_applied_target_position = _target_position

    target_changed.emit(_target_position)

    if debug_print_state:
        print("[PathfindingModule] target updated: ", _target_position)


func _should_use_fallback_direct_path() -> bool:
    return navigation_agent == null or debug_disable_navigation_agent


func _fallback_direct_path() -> void:
    if character == null:
        _clear_path_velocity()
        return

    var delta_to_target := _target_position - character.global_position
    if delta_to_target.length() <= arrive_distance:
        _clear_path_velocity()
        _emit_navigation_finished_once()
        return

    _finished_emitted = false
    _apply_path_velocity(delta_to_target.normalized() * max_speed)


func _apply_path_velocity(v: Vector2) -> void:
    if movement == null:
        return

    if auto_set_path_mode:
        movement.set_path_mode()

    movement.set_path_velocity(v)


func _clear_path_velocity() -> void:
    if movement:
        movement.set_path_velocity(Vector2.ZERO)


func _emit_navigation_finished_once() -> void:
    if not _finished_emitted:
        _finished_emitted = true
        navigation_finished.emit()


# -------------------------
# Navigation Callbacks
# -------------------------


func _on_velocity_computed(safe_velocity: Vector2) -> void:
    if not enabled:
        _clear_path_velocity()
        return

    _apply_path_velocity(safe_velocity)


func _on_navigation_finished() -> void:
    _clear_path_velocity()
    _emit_navigation_finished_once()


# -------------------------
# Config API
# -------------------------


func set_speed(value: float) -> void:
    max_speed = max(0.0, value)

    if navigation_agent:
        navigation_agent.max_speed = max_speed


func set_arrive_distance(value: float) -> void:
    arrive_distance = max(0.0, value)

    if navigation_agent:
        navigation_agent.target_desired_distance = arrive_distance


# -------------------------
# Debug / Test Helpers
# -------------------------


func debug_print_target_state() -> void:
    print(
        {
            "enabled": enabled,
            "has_target": has_target(),
            "target_position": _target_position,
            "follow_target": _follow_target,
            "path_finished": is_path_finished()
        }
    )
