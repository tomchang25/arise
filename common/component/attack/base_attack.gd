class_name BaseAttack
extends Node2D

@export var attack_cooldown: float = 0.5
# @export var attack_range: float = -1

@export var max_targets: int = 1

var cooldown_timer: Timer
var locked := false
var targets_hit_count: int = 0

## --- GDScript Lifecycle ---


func _ready() -> void:
    _setup_timer()
    _initialize_attack()


func _setup_timer() -> void:
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true
    cooldown_timer.timeout.connect(_on_cooldown_timer_timeout)
    add_child(cooldown_timer)


func _on_hit_confirmed() -> void:
    targets_hit_count += 1
    if targets_hit_count >= max_targets:
        _on_max_targets_reached()


func _on_cooldown_timer_timeout() -> void:
    locked = false


## --- Virtual methods ---


func _execute_attack_logic(_target_position: Vector2) -> void:
    pass


func _on_max_targets_reached() -> void:
    pass


func _initialize_attack() -> void:
    pass


## --- Public API ---


## Points the attack node toward a specific target
func aim_at(target_global_position: Vector2) -> void:
    var direction_vector: Vector2 = (target_global_position - global_position).normalized()
    global_rotation = direction_vector.angle()


func can_attack() -> bool:
    return not locked


func start_attack(target_position: Vector2) -> void:
    if locked:
        return

    targets_hit_count = 0
    locked = true
    _execute_attack_logic(target_position)


func end_attack() -> void:
    cooldown_timer.start()
