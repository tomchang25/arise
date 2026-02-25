class_name State
extends Node

signal transition_requested(from: State, to: int)

var state_id: int = -1

var _locked := false


# --- Virtual Methods (To be Overridden by Subclasses) ---
func _enter() -> void:
    pass


func _exit() -> void:
    pass


func _update(_delta: float) -> void:
    pass


# --- Public API Methods ---
func enter() -> void:
    _enter()
    _locked = false


func exit() -> void:
    _exit()
    _locked = true


func update(delta: float) -> void:
    _update(delta)


func change_state(to: int) -> void:
    if _locked:
        return

    _locked = true
    transition_requested.emit(self, to)
