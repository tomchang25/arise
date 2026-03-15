class_name GroupMemberEntry
extends Resource

@export var scene: PackedScene
@export var min_count: int = 1
@export var max_count: int = 1


func is_valid() -> bool:
	return scene != null and max_count >= 1
