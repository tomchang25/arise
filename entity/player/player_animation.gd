# PlayerAnimation.gd (Component)
class_name PlayerAnimation
extends Node

signal animation_finished(anim_name: StringName)

const ANIMATION_STATE_IDLE = "Idle"
const ANIMATION_STATE_MOVE = "Move"
const ANIMATION_STATE_RUN = "Run"
const ANIMATION_STATE_ATTACK = "Attack"
const ANIMATION_STATE_ROLL = "Roll"

const ANIMATION_STATES = [ANIMATION_STATE_IDLE, ANIMATION_STATE_MOVE, ANIMATION_STATE_RUN, ANIMATION_STATE_ATTACK, ANIMATION_STATE_ROLL]

@export var animation_tree: AnimationTree
# @export var movement: PlayerMovement

@onready var animation_state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/StateMachine/playback")

var animation_direction = Vector2.ZERO


func _ready():
    animation_tree.active = true

    animation_tree.animation_finished.connect(func(anim_name: StringName): animation_finished.emit(anim_name))


# Called by the States to trigger a new animation transition
func travel_to_state(state_name: String):
    animation_state_machine.travel(state_name)


func set_time_scale(time_scale: float):
    animation_tree.set("parameters/TimeScale/scale", time_scale)


func set_animation_direction(new_direction: Vector2):
    if animation_direction == new_direction:
        return

    animation_direction = new_direction
    for state in ANIMATION_STATES:
        animation_tree.set("parameters/StateMachine/" + state + "/blend_position", animation_direction)

    # print("Animation direction set to " + str(animation_direction))
