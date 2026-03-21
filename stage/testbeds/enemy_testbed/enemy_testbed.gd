extends Node2D

@onready var ninja_yellow: Enemy = $NinjaYellow


func _ready() -> void:
    ninja_yellow.global_position = Vector2(500,200)
    ninja_yellow.anchor_position = Vector2(500,200)
    
