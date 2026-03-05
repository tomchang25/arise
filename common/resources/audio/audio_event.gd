class_name AudioEvent
extends Resource

@export_group("Streams")
@export var streams: Array[AudioStream] = []

@export_group("Playback")
@export var bus: StringName = &"SFX"
@export var volume_db: float = 0.0

@export_group("Pitch Randomization")
@export var pitch_min: float = 0.95
@export var pitch_max: float = 1.05

@export_group("Limiter")
@export var limiter_key: StringName = &""
@export var max_per_window: int = 4
@export var window_sec: float = 0.05

func pick_stream() -> AudioStream:
    if streams.is_empty():
        return null
    return streams[randi() % streams.size()]
