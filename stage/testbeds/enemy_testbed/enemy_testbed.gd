extends Node2D

@onready var ninja_red: RedNinja = $Ninja_red

func _ready() -> void:
    ninja_red.global_position = Vector2(500,200)
    ninja_red.home_position = Vector2(500,200)
    
