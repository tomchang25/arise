extends Node2D

@onready var ninja_red: RedNinja = $Ninja_red
@onready var blue_slime: BlueSlime = $BlueSlime

func _ready() -> void:
    ninja_red.global_position = Vector2(500,200)
    ninja_red.home_position = Vector2(500,200)
    
    blue_slime.global_position = Vector2(200,200)
    blue_slime.home_position = Vector2(200,200)
