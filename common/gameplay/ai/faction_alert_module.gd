class_name FactionAlertModule
extends Node2D

@export var faction_group: String = "Enemies"
@export var broadcast_range: float = 600.0

var enabled: bool = true


func _ready() -> void:
    owner.add_to_group(faction_group)


func reset() -> void:
    enabled = true


func set_enabled(value: bool) -> void:
    enabled = value


## Tell allies about a target
func alert_allies(target: Node2D) -> void:
    if not enabled:
        return
    if is_instance_valid(target):
        get_tree().call_group(faction_group, "on_broadcast_received", target, global_position)


## Listen for alerts from others
func on_broadcast_received(target: Node2D, origin: Vector2) -> void:
    if not enabled:
        return
    if global_position.distance_to(origin) <= broadcast_range:
        if owner.has_method("handle_external_target"):
            owner.handle_external_target(target)
