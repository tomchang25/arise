@tool
class_name UiAudioEvent
extends AudioEvent

@export_group("Pitch")
@export var pitch_min: float = 0.98
@export var pitch_max: float = 1.02

@export_group("Limiter")
@export var limiter_key: StringName = &""
@export var max_per_window: int = 8
@export var window_sec: float = 0.05


func _init() -> void:
    bus_id = AudioBus.Id.UI
