@abstract
class_name AttackModule
extends Node2D
## Shared abstract base for all attack module types.
##
## DetachedAttackModule and AttachedAttackModule both extend this class,
## giving CombatModule a single type to work with — no is-checks needed
## for the common API.
##
## Unified API (both types):
##   execute_attack(target_position)  — start / activate
##   end_attack()                     — cooldown / deactivate
##   can_attack() -> bool             — ready check
##
## AttachedAttackModule maps execute_attack → activate and end_attack → deactivate.
## DetachedAttackModule uses execute_attack for fire-and-forget and end_attack to
## start the cooldown timer.

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


func _on_enabled_changed(_value: bool) -> void:
    pass # subclass overrides this
