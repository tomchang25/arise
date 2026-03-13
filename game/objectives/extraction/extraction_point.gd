class_name ExtractionPoint
extends Area2D

signal extracted
signal hold_progress_changed(progress: float)

# -------------------------
# Configuration
# -------------------------

@export var hold_duration: float = 3.0

# -------------------------
# State
# -------------------------

var _active: bool = false
var _hold_timer: float = 0.0
var _player_inside: bool = false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    _set_visible(false)


func _process(delta: float) -> void:
    if not _active or not _player_inside:
        return

    _hold_timer += delta
    hold_progress_changed.emit(_hold_timer / hold_duration)

    if _hold_timer >= hold_duration:
        _on_extraction_complete()


# -------------------------
# Public API
# -------------------------


func activate() -> void:
    _active = true
    _hold_timer = 0.0
    _set_visible(true)


func deactivate() -> void:
    _active = false
    _hold_timer = 0.0
    _player_inside = false
    _set_visible(false)


# -------------------------
# Internal
# -------------------------


func _set_visible(value: bool) -> void:
    visible = value
    set_process(value)


func _on_extraction_complete() -> void:
    _active = false
    EventBus.extraction_completed.emit()
    extracted.emit()


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_body_entered(body: Node) -> void:
    if not _active:
        return
    if body.is_in_group(&"player"):
        _player_inside = true
        _hold_timer = 0.0


func _on_body_exited(body: Node) -> void:
    if body.is_in_group(&"player"):
        _player_inside = false
        _hold_timer = 0.0
        hold_progress_changed.emit(0.0)
