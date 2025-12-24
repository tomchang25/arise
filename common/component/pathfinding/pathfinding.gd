class_name Pathfinding
extends Node2D

@export var enabled := true
# @export var target_update_interval: float = 5.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var update_timer: Timer = $UpdateTimer

var _target_velocity: Vector2
var _max_speed: float

## --- GDScript Lifecycle ---


func _ready():
    if not navigation_agent:
        push_error("Pathfinding must have a NavigationAgent2D child node")
        return

    navigation_agent.velocity_computed.connect(_on_velocity_computed)


func _physics_process(_delta):
    if not enabled:
        return

    # 1. Pathfinding (Runs only when the target changes or the current path is invalidated)
    if navigation_agent.is_navigation_finished():
        _target_velocity = Vector2.ZERO
        return

    # 2. Calculate the Desired Velocity from the Navigation Agent (Target Force)
    var next_point = navigation_agent.get_next_path_position()
    var target_force = (next_point - global_position).normalized() * _max_speed

    if navigation_agent.avoidance_enabled:
        navigation_agent.set_velocity(target_force)
    else:
        _target_velocity = target_force


func _on_velocity_computed(safe_velocity: Vector2):
    _target_velocity = safe_velocity


## --- Public API for Setting Movement State ---


func get_velocity() -> Vector2:
    return _target_velocity


func set_speed(new_speed: float):
    navigation_agent.max_speed = new_speed
    _max_speed = new_speed


func set_arrive_distance(new_distance: float):
    navigation_agent.target_desired_distance = new_distance


func set_target_position(new_target_pos: Vector2):
    navigation_agent.target_position = new_target_pos
