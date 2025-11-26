# PlayerMovement.gd (Component)
class_name PlayerMovement
extends Node

# Export properties for speed, controlled by the Movement Component
@export var idle_speed: float = 0.0
@export var walk_speed: float = 75.0
@export var run_speed: float = 125.0
@export var roll_speed: float = 150.0

@onready var player: CharacterBody2D = get_owner()

# Variables set by the active State
var current_target_speed: float = 0.0
var current_direction: Vector2 = Vector2.ZERO

var velocity: Vector2:
    get:
        return current_direction * current_target_speed

## --- Input Reading Utilities ---


func get_input_direction() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_run_pressed() -> bool:
    return Input.is_action_pressed("run")


func is_roll_pressed() -> bool:
    return Input.is_action_pressed("roll")


func is_attack_pressed() -> bool:
    return Input.is_action_pressed("attack")


## --- Physics Processing (CORE MOVEMENT LOGIC) ---


func _physics_process(_delta: float):
    player.velocity = self.velocity
    player.move_and_slide()


## --- Public API for States ---


func stop():
    current_target_speed = 0.0
    current_direction = Vector2.ZERO


func set_direction(direction: Vector2) -> void:
    current_direction = direction


func update_direction() -> void:
    current_direction = self.get_input_direction()


func set_idle_speed() -> void:
    _apply_speed(idle_speed)


func set_walk_speed() -> void:
    _apply_speed(walk_speed)


func set_run_speed() -> void:
    _apply_speed(run_speed)


func set_roll_speed() -> void:
    _apply_speed(roll_speed)


## --- Private Helpers ---


func _apply_speed(speed: float) -> void:
    current_target_speed = speed
