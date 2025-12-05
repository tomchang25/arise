class_name FollowPlayer
extends Node

@export var enabled := true
@export var who: CharacterBody2D

@export var move_speed: float = 100.0

@export var navigation_agent: NavigationAgent2D

@export var target_update_interval: float = 5.0

var target_position: Vector2  # Where the army member is trying to go

var target_update_timer: float = 0

var movement_vector: Vector2


# Called when the node enters the scene tree for the first time.
func _ready():
    # Connect signal to know when pathfinding is complete
    navigation_agent.velocity_computed.connect(_on_velocity_computed)
    # Set the movement physics process
    set_physics_process(true)


# Function to be called from the Player script
func set_target(new_target_pos: Vector2):
    # This is the destination position (e.g., player's current location or a point near the enemy)
    target_position = new_target_pos
    navigation_agent.target_position = target_position

    # Reset the target update timer
    target_update_timer = 0


func set_arrive_distance(new_distance: float):
    navigation_agent.target_desired_distance = new_distance


func _physics_process(delta):
    if not enabled:
        return

    # 1. Pathfinding (Runs only when the target changes or the current path is invalidated)
    if navigation_agent.is_navigation_finished():
        movement_vector = Vector2.ZERO
        return

    # 2. Calculate the Desired Velocity from the Navigation Agent (Target Force)
    var next_point = navigation_agent.get_next_path_position()
    var target_force = (next_point - who.global_position).normalized() * move_speed
    target_force = target_force.limit_length(move_speed)

    if navigation_agent.avoidance_enabled:
        navigation_agent.set_velocity(target_force)
    else:
        movement_vector = target_force

    target_update_timer += delta


# This function is called by the NavigationAgent with the calculated steering velocity
func _on_velocity_computed(safe_velocity: Vector2):
    var remaining_time = target_update_interval - target_update_timer
    var ratio = max(0.0, remaining_time / target_update_interval)

    movement_vector = safe_velocity * ratio
