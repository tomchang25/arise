class_name AudioEvent
extends Resource

@export var volume_db: float = 0.0

@export_group("Bus")
@export var bus_id: AudioBus.Id = AudioBus.Id.NONE
@export var bus_override: StringName = &""

@export_group("Streams")
@export var streams: Array[AudioStream] = []


func pick_stream() -> AudioStream:
    if streams.is_empty():
        return null
    return streams[randi() % streams.size()]
