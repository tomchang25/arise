class_name ObjectiveManager
extends Node

signal objective_changed(objective: Objective)
signal objective_completed(objective: Objective)

# -------------------------
# State
# -------------------------

var current_objective: Objective = null

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _subscribe_event_bus()


# -------------------------
# Public API
# -------------------------


func register(objective: Objective) -> void:
    if current_objective != null:
        _disconnect_objective(current_objective)

    current_objective = objective

    if current_objective == null:
        EventBus.objective_changed.emit(null)
        objective_changed.emit(null)
        return

    current_objective.activate()
    current_objective.objective_completed.connect(_on_objective_completed)

    EventBus.objective_changed.emit(current_objective)
    objective_changed.emit(current_objective)


func clear() -> void:
    register(null)


# -------------------------
# Internal
# -------------------------


func _subscribe_event_bus() -> void:
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.extraction_completed.connect(_on_extraction_completed)


func _disconnect_objective(objective: Objective) -> void:
    if objective.objective_completed.is_connected(_on_objective_completed):
        objective.objective_completed.disconnect(_on_objective_completed)
    objective.deactivate()


func _forward_event(event_name: StringName, payload: Variant = null) -> void:
    if current_objective == null or not current_objective.active:
        return
    current_objective.on_event(event_name, payload)


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_enemy_killed(enemy: Node) -> void:
    _forward_event(&"enemy_killed", enemy)


func _on_extraction_completed() -> void:
    _forward_event(&"extraction_completed")


func _on_objective_completed() -> void:
    var completed := current_objective

    if current_objective != null:
        _disconnect_objective(current_objective)
        current_objective = null

    EventBus.objective_completed.emit(completed)
    objective_completed.emit(completed)
