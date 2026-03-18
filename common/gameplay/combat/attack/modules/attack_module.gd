@abstract
class_name AttackModule
extends Node2D
## Shared abstract base for all attack module types.
##
## DetachedAttackModule and AttachedAttackModule both extend this class,
## giving CombatModule a single type to work with — no is-checks needed
## for the common API.
##
## All methods below warn if called on a subclass that did not override them.
## Subclasses override only the methods relevant to their delivery type.

var enabled: bool = true:
    set(value):
        if enabled == value:
            return
        enabled = value
        _on_enabled_changed(value)


@abstract
func can_attack() -> bool


func execute_attack(_target_position: Vector2) -> void:
    push_warning("%s: execute_attack() is not implemented" % get_class())


func end_attack() -> void:
    push_warning("%s: end_attack() is not implemented" % get_class())


func activate_attack() -> void:
    push_warning("%s: activate_attack() is not implemented" % get_class())


func deactivate_attack() -> void:
    push_warning("%s: deactivate_attack() is not implemented" % get_class())


func _on_enabled_changed(_value: bool) -> void:
    pass # subclass overrides this
