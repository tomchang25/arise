class_name Enemy
extends CharacterBody2D

signal damaged(attack: Attack)

@export var detection_radius := 100.0
@export var chase_radius := 200.0
@export var follow_radius := 25.0

@onready var sprite := $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox


func _ready() -> void:
    hitbox.damaged.connect(_on_damaged)


func _on_damaged(attack: Attack) -> void:
    print("Enemy damaged", self.name)
    damaged.emit(attack)
