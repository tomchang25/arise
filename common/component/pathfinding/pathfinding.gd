class_name Pathfinding
extends Node2D

@export var enabled := true
@export var movement: BaseMovement
# @export var target_update_interval: float = 5.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var update_timer: Timer = $UpdateTimer

var target_node: Node2D

var _target_velocity: Vector2
var _max_speed: float

## --- GDScript Lifecycle ---


func _ready():
    if not navigation_agent:
        push_error("Pathfinding must have a NavigationAgent2D child node")
        return

    navigation_agent.velocity_computed.connect(_on_velocity_computed)
    update_timer.timeout.connect(_on_update_timer_timeout)


func _physics_process(_delta):
    if not enabled or not target_node:
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
    # var remaining_time = target_update_interval - target_update_timer
    # var ratio = max(0.0, remaining_time / target_update_interval)

    # movement_vector = safe_velocity * ratio

    _target_velocity = safe_velocity


func _on_update_timer_timeout():
    if not enabled or not target_node:
        return

    update_target_position()


## --- Public API for Setting Movement State ---

# func set_target(new_target_pos: Vector2):
#     navigation_agent.target_position = new_target_pos
#     target_update_timer = 0


func get_velocity() -> Vector2:
    return _target_velocity


func set_target(new_target_node: Node2D):
    target_node = new_target_node


func set_speed(new_speed: float):
    navigation_agent.max_speed = new_speed
    _max_speed = new_speed


func set_arrive_distance(new_distance: float):
    navigation_agent.target_desired_distance = new_distance


func update_target_position():
    navigation_agent.target_position = target_node.global_position
