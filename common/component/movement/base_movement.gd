class_name BaseMovement
extends Node

@onready var character: CharacterBody2D = get_owner()

# Variables set by the active State or Input/Pathfinding component
var current_target_speed: float = 0.0
var current_direction: Vector2 = Vector2.ZERO

# Calculated velocity property
var velocity: Vector2:
    get:
        return current_direction * current_target_speed

## --- Physics Processing (CORE MOVEMENT LOGIC) ---


# Note: The _physics_process moves the character based on the current velocity
# set by the public API functions.
func _physics_process(_delta: float):
    # Apply the calculated velocity to the CharacterBody2D
    character.velocity = self.velocity
    character.move_and_slide()


## --- Public API for Setting Movement State ---


func set_direction(direction: Vector2) -> void:
    # Ensure the direction is normalized if it's not already
    current_direction = direction.normalized()


func apply_speed(speed: float) -> void:
    current_target_speed = speed


func stop() -> void:
    set_direction(Vector2.ZERO)
    apply_speed(0)

## --- Private Helpers ---
