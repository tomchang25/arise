class_name Objective
extends Resource

signal objective_completed

# -------------------------
# State
# -------------------------

var active: bool = false

# -------------------------
# Common API
# -------------------------


func get_objective_text() -> String:
    return ""


func activate() -> void:
    active = true


func deactivate() -> void:
    active = false


# -------------------------
# Event Handling
# -------------------------


## Called by ObjectiveManager for every EventBus event.
## Subclasses override this to react to relevant events.
func on_event(_event_name: StringName, _payload: Variant = null) -> void:
    pass


# -------------------------
# Internal
# -------------------------


func _complete() -> void:
    if not active:
        return
    active = false
    objective_completed.emit()
