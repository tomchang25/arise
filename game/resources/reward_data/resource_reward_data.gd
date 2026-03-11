class_name ResourceRewardData
extends Resource

@export_group("Identity")
@export var id: StringName = &""
@export var sprite: Texture2D
@export var label: String = ""
@export_multiline var description: String = ""


func is_valid() -> bool:
    return id != StringName()


func execute_effect(_collector: Node, _amount: int) -> bool:
    return false
