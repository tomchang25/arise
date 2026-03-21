class_name ObjectiveHUD
extends Control

# -------------------------
# Exports
# -------------------------

@export var objective_manager: ObjectiveManager
@export var label_path: NodePath = ^"ObjectiveLabel"

# -------------------------
# Handles
# -------------------------

var _label: Label

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _label = get_node_or_null(label_path) as Label

    if _label == null:
        push_warning("ObjectiveHUD: Label not found at path: %s" % label_path)

    if objective_manager:
        objective_manager.objective_changed.connect(_on_objective_changed)
        objective_manager.objective_completed.connect(_on_objective_completed)

    _refresh(null)


# -------------------------
# Internal
# -------------------------


func _refresh(objective: Objective) -> void:
    if _label == null:
        return

    if objective == null:
        visible = false
        return

    _label.text = objective.get_objective_text()
    visible = true


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_objective_changed(objective: Objective) -> void:
    _refresh(objective)


func _on_objective_completed(_objective: Objective) -> void:
    _refresh(null)
