@tool
class_name Health
extends Node2D

signal health_changed(health: float)
signal health_depleted

# @export var hitbox: Hitbox

@export_category("Debug")
@export var enable_health_label := false:
    set(value):
        enable_health_label = value
        _update_health_label()

@export var max_health := 10.0

@onready var health := max_health:
    set(value):
        health = value
        health_changed.emit(health)

@onready var debug_health_label: Label = $DebugHealthLabel


func _ready():
    # if hitbox:
    #     hitbox.damaged.connect(on_damaged)

    _update_health_label()

    health_changed.connect(_on_health_changed)


func reset():
    health = max_health


func on_damaged(attack: Attack):
    health -= attack.damage
    health_changed.emit(health)

    if health <= 0:
        health = 0
        health_depleted.emit()


func _on_health_changed(_new_health: float) -> void:
    print("Health changed to ", health)
    _update_health_label()


func _update_health_label():
    if not enable_health_label:
        debug_health_label.visible = false
        return

    debug_health_label.visible = true
    debug_health_label.text = "HP: " + str(health)
