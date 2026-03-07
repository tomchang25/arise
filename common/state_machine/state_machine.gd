class_name StateMachine
extends Node

@export var initial_state: State
@onready var target: Node = owner

var current_state: State
var states: Dictionary = {}


func _ready() -> void:
    if target and not target.is_node_ready():
        await target.ready

    states.clear()

    for child in get_children():
        if child is State:
            var state := child as State
            if state.state_id < 0:
                push_warning("StateMachine: state '%s' has invalid state_id" % state.name)
                continue

            states[state.state_id] = state
            if not state.transition_requested.is_connected(_on_transition_requested):
                state.transition_requested.connect(_on_transition_requested)

    if initial_state == null:
        push_error("StateMachine must have an initial_state")
        return

    if not states.has(initial_state.state_id):
        push_error("StateMachine initial_state is not registered in children")
        return

    current_state = initial_state
    current_state.enter()


func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)


func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)


func _on_transition_requested(from: State, to: int) -> void:
    if from != current_state:
        return

    if not states.has(to):
        push_warning("StateMachine: missing target state id %s" % str(to))
        return

    var new_state := states[to] as State
    if new_state == current_state:
        return

    current_state.exit()
    current_state = new_state
    current_state.enter()
