class_name FollowPlayer
extends Node

@export var who: CharacterBody2D

@export var move_speed: float = 200.0
@export var follow_distance: float = 50.0  # Ideal distance to player
@export var separation_weight: float = 1.0  # For flocking/separation behavior

@export var navigation_agent: NavigationAgent2D

var target_position: Vector2  # Where the army member is trying to go


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

func _physics_process(_delta):
    # 1. Pathfinding (Runs only when the target changes or the current path is invalidated)
    if navigation_agent.is_navigation_finished():
        # You can add logic here if you want to constantly update the target even if it hasn't moved far
        return

    # 2. Get the next point on the path
    var next_point = navigation_agent.get_next_path_position()

    # 3. Calculate steering velocity towards the next point
    var desired_velocity = (next_point - who.global_position).normalized() * move_speed

    # 4. Give this velocity to the NavigationAgent for smooth steering and obstacle avoidance
    navigation_agent.set_velocity(desired_velocity)


# This function is called by the NavigationAgent with the calculated steering velocity
func _on_velocity_computed(safe_velocity: Vector2):    
    who.velocity = safe_velocity
    who.move_and_slide()
