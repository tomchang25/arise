class_name StateMachine
extends Node

@export var initial_state: State

var current_state: State
var states := {}


func _ready() -> void:
    for child in get_children():
        if child is State:
            # print(child.state_id, child.name)
            states[child.state_id] = child
            child.transition_requested.connect(_on_transition_requested)

    if initial_state == null:
        push_error("StateMachine must have an initial state")
        return

    current_state = initial_state
    current_state.enter()


func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)


func _on_transition_requested(from: State, to: int) -> void:
    if from != current_state:
        push_error("transition requested from ", from.name, " to ", states[to].name, " but current state is ", current_state.name)
        return

    # print("transitioning from ", from.name, " to ", states[to].name)

    var new_state: State = states[to]
    if not new_state:
        return

    if current_state:
        current_state.exit()

    new_state.enter()
    current_state = new_state
