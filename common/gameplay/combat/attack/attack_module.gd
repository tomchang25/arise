@abstract
class_name AttackModule
extends Node2D

var enabled: bool = true


@abstract
func can_attack() -> bool


func execute_attack(_target_position: Vector2, _data: AttackData) -> void:
    pass


func end_attack() -> void:
    pass


func activate_attack(_data: AttackData) -> void:
    pass


func deactivate_attack() -> void:
    pass
