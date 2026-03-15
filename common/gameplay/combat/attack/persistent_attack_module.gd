class_name PersistentAttackModule
extends Node2D

var is_active: bool = false


# -------------------------
# Common API
# -------------------------


## Enable the persistent hitbox with the given attack data.
func activate_attack(data: AttackData) -> void:
	if data == null:
		push_error("PersistentAttackModule: data is null")
		return

	is_active = true
	_activate_logic(data)


## Disable the persistent hitbox.
func deactivate_attack() -> void:
	is_active = false
	_deactivate_logic()


# -------------------------
# Internal — override in subclasses
# -------------------------


func _activate_logic(_data: AttackData) -> void:
	pass


func _deactivate_logic() -> void:
	pass
