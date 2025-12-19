class_name PlayerInput
extends Node

## --- Input Reading Utilities ---


# Returns a normalized Vector2 representing the player's movement direction.
func get_movement_direction() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


# Returns true if the 'Run' action is currently being held down.
func is_run_pressed() -> bool:
    return Input.is_action_pressed("run")


# Returns true if the 'Roll' action was just pressed (on the frame it happened).
func is_roll_pressed() -> bool:
    return Input.is_action_pressed("roll")


# Returns true if the 'Attack' action was pressed.
func is_attack_pressed() -> bool:
    return Input.is_action_pressed("attack")
