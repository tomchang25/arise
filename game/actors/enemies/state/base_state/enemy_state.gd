class_name EnemyState
extends State

enum EnemyStateId { NULL = -1, IDLE = 0, WANDER = 1, CHASE = 2, ATTACK = 3, BACK = 4 }

var enemy: Enemy


func _ready() -> void:
    await owner.ready
    enemy = owner

    # enemy.wait_timer.timeout.connect(_on_wait_timer_timeout)


func _on_updated_next_position(_position: Vector2) -> void:
    pass

# func _on_wait_timer_timeout() -> void:
#     pass
