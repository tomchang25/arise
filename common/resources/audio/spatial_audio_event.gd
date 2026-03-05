@tool
class_name SpatialAudioEvent
extends AudioEvent

@export_group("Pitch")
@export var pitch_min: float = 0.95
@export var pitch_max: float = 1.05

@export_group("Limiter")
@export var limiter_key: StringName = &""
@export var max_per_window: int = 4
@export var window_sec: float = 0.05


func _init() -> void:
    bus_id = AudioBus.Id.SOUND
