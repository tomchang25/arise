class_name Enemy
extends CharacterBody2D

signal damaged(attack: Attack)

@export var detection_radius := 100.0
@export var chase_radius := 200.0
@export var follow_radius := 25.0

@onready var sprite := $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var health_component: Health = $Health
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
    hitbox.damaged.connect(_on_damaged)

    health_component.health_changed.connect(_on_health_changed)
    health_component.health_depleted.connect(_on_health_depleted)

    health_label.text = "HP: " + str(health_component.health)


func _on_damaged(attack: Attack) -> void:
    damaged.emit(attack)


func _on_health_changed(health: float) -> void:
    var overlay_ratio = (1 - (health / health_component.max_health)) * 0.5
    sprite.material.set_shader_parameter("overlay_amount", overlay_ratio)
    health_label.text = "HP: " + str(health_component.health)


func _on_health_depleted() -> void:
    queue_free()
