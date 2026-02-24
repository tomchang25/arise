class_name Pathfinding
extends Node2D

@export var enabled := true
## How often (in seconds) the NavigationAgent updates its internal path.
@export var target_update_interval: float = 0.2

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

var _target_velocity: Vector2
var _max_speed: float

var _timer: float = 0.0
var _pending_target_pos: Vector2
## --- GDScript Lifecycle ---


func _ready():
    if not navigation_agent:
        push_error("Pathfinding must have a NavigationAgent2D child node")
        return

    navigation_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(delta):
    if not enabled:
        return

    # --- Optimization: Only update the agent's target at intervals ---
    _timer += delta
    if _timer >= target_update_interval:
        if navigation_agent.target_position != _pending_target_pos:
            navigation_agent.target_position = _pending_target_pos
        _timer = 0.0

    # --- Movement Calculation: Still runs every frame for smoothness ---
    if navigation_agent.is_navigation_finished():
        _target_velocity = Vector2.ZERO
        return

    var next_point = navigation_agent.get_next_path_position()
    var target_force = (next_point - global_position).normalized() * _max_speed

    if navigation_agent.avoidance_enabled:
        navigation_agent.set_velocity(target_force)
    else:
        _target_velocity = target_force


func _on_velocity_computed(safe_velocity: Vector2):
    if not enabled:
        _target_velocity = Vector2.ZERO

    _target_velocity = safe_velocity


## --- Public API for Setting Movement State ---


func set_target_position(new_target_pos: Vector2):
    # Just store the value; _physics_process will apply it to the agent [cite: 37]
    _pending_target_pos = new_target_pos


# func set_target_position(new_target_pos: Vector2):
#     navigation_agent.target_position = new_target_pos


func get_velocity() -> Vector2:
    if not enabled:
        push_warning("Pathfinding is disabled")

    return _target_velocity


func set_speed(new_speed: float):
    navigation_agent.max_speed = new_speed
    _max_speed = new_speed


func set_arrive_distance(new_distance: float):
    navigation_agent.target_desired_distance = new_distance
