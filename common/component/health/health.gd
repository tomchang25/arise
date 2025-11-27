class_name Health
extends Node

signal health_changed(health: float)
signal health_depleted

@export var hitbox: Hitbox

@export var max_health := 10.0
@onready var health := max_health


func _ready():
    if hitbox:
        hitbox.damaged.connect(on_damaged)


func reset():
    health = max_health


func on_damaged(attack: Attack):
    health -= attack.damage
    health_changed.emit(health)

    if health <= 0:
        health = 0
        health_depleted.emit()
