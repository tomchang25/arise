# animation_component.gd
class_name BaseAnimation extends Node

signal animation_finished(anim_name: StringName)

# --- Godot Components ---
@export var animation_tree: AnimationTree
@onready var animation_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

var _prev_animation_direction: Vector2
# var _animation_states: Array[String] = []


# --- Initialization ---
func _ready():
    animation_tree.animation_finished.connect(func(anim_name: StringName): animation_finished.emit(anim_name))


# --- Core Animation Control Functions ---


# Travels to a new state in the AnimationTree StateMachine
func travel_to_state(state_name: String):
    animation_state_machine.travel(state_name)


# Sets the playback speed (Using the number 1.0 is normal speed, 0.5 is half speed, etc.)
func set_time_scale(time_scale: float):
    animation_tree.set("parameters/TimeScale/scale", time_scale)


# Sets the blend position for states that use a BlendSpace2D (like movement)
func set_animation_direction(new_direction: Vector2, anim_name: StringName = get_current_animation_state()):
    animation_tree.set("parameters/StateMachine/" + anim_name + "/blend_position", new_direction)
    _prev_animation_direction = new_direction


func set_as_prev_animation_direction(anim_name: StringName = get_current_animation_state()):
    animation_tree.set("parameters/StateMachine/" + anim_name + "/blend_position", _prev_animation_direction)


# --- Utility Function for State Logic ---


# Check if the last animation that finished matches the specified state named
func get_current_animation_state() -> StringName:
    return animation_state_machine.get_current_node()
