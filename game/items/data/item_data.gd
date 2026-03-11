class_name ItemData
extends Resource

@export_group("Identity")
@export var id: StringName = &""
@export var sprite: Texture2D
@export var label: String = ""
@export_multiline var description: String = ""


func is_valid() -> bool:
    return id != StringName()
