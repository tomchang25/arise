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


func _physics_process(_delta: float):
    character.velocity = self.velocity
    character.move_and_slide()


## --- Public API for Setting Movement State ---


func set_velocity(new_velocity: Vector2) -> void:
    current_direction = new_velocity.normalized()
    current_target_speed = new_velocity.length()


func set_direction(new_direction: Vector2) -> void:
    # Ensure the direction is normalized if it's not already
    current_direction = new_direction.normalized()


func set_speed(new_speed: float) -> void:
    current_target_speed = new_speed


func stop() -> void:
    set_direction(Vector2.ZERO)
    set_speed(0)

## --- Private Helpers ---
