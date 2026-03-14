class_name State
extends Node

signal transition_requested(from: State, to: int)

@export var state_id: int = -1

var _locked := false


func _ready() -> void:
    if state_id == -1:
        push_error("State must have a state_id")


func _enter() -> void:
    pass


func _exit() -> void:
    pass


func _update(_delta: float) -> void:
    pass


func _physics_update(_delta: float) -> void:
    pass


func enter() -> void:
    _locked = false
    _enter()


func exit() -> void:
    _locked = true
    _exit()


func update(delta: float) -> void:
    if _locked:
        return
    _update(delta)


func physics_update(delta: float) -> void:
    if _locked:
        return
    _physics_update(delta)


func change_state(to: int) -> void:
    if _locked:
        return
    if to == state_id:
        return

    _locked = true
    transition_requested.emit(self, to)
