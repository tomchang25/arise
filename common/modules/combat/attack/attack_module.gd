class_name AttackModule
extends Node2D

@export var attack_cooldown: float = 0.5

var cooldown_timer: Timer
var locked := false


func _ready() -> void:
    _setup_timer()


func _setup_timer() -> void:
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true
    cooldown_timer.timeout.connect(func(): locked = false)
    add_child(cooldown_timer)


func can_attack() -> bool:
    return not locked


func execute_attack(target_position: Vector2, info: AttackInfo) -> void:
    if locked:
        return

    if info == null:
        push_error("AttackModule: info is null")
        return

    if info.effect_scene == null:
        push_error("AttackModule: info.effect_scene is null")
        return

    locked = true
    _execute_attack_logic(target_position, info)


func end_attack() -> void:
    if cooldown_timer.is_stopped():
        cooldown_timer.start()


func _execute_attack_logic(_target_position: Vector2, _info: AttackInfo) -> void:
    pass
