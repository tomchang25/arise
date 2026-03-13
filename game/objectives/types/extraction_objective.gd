class_name ExtractionObjective
extends Objective

# -------------------------
# State
# -------------------------

var _extraction_point: ExtractionPoint = null

# -------------------------
# Common API
# -------------------------


func get_objective_text() -> String:
    return "Reach the extraction point"


## Call this before passing the objective to ObjectiveManager.register().
## Example:
##   var obj := ExtractionObjective.new()
##   obj.setup($ExtractionPoint)
##   objective_manager.register(obj)
func setup(point: ExtractionPoint) -> void:
    _extraction_point = point


func activate() -> void:
    super.activate()

    if _extraction_point == null:
        push_warning("ExtractionObjective: call setup(point) before registering.")
        return

    _extraction_point.extracted.connect(_on_extracted)
    _extraction_point.activate()


func deactivate() -> void:
    super.deactivate()

    if _extraction_point == null:
        return

    if _extraction_point.extracted.is_connected(_on_extracted):
        _extraction_point.extracted.disconnect(_on_extracted)

    _extraction_point.deactivate()


# -------------------------
# Event Handling
# -------------------------


func on_event(_event_name: StringName, _payload: Variant = null) -> void:
    # ExtractionObjective reacts via direct signal from ExtractionPoint,
    # not through the EventBus forwarding chain.
    pass


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_extracted() -> void:
    _complete()
