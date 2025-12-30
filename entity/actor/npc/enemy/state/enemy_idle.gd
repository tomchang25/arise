extends EnemyState

@export var animation_state: String = "Idle"

@export var min_wait_time: float = 3.0
@export var max_wait_time: float = 10.0


func _init() -> void:
    state_id = EnemyStateId.IDLE


func _enter() -> void:
    enemy.movement.stop()

    enemy.animation.travel_to_state(animation_state)

    # _setup_wait_timer()


func _update(_delta: float) -> void:
    if enemy.enemy_scanner.is_enemy_tracked():
        change_state(EnemyStateId.CHASE)
        return

    if enemy.next_position.distance_to(enemy.global_position) > 10:
        change_state(EnemyStateId.WANDER)
        return


# func _on_updated_next_position(_position: Vector2) -> void:
#     print(enemy.next_position)
#     change_state(EnemyStateId.WANDER)
#     return


func _exit() -> void:
    pass
