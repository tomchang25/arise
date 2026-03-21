extends EnemyState

@export var wander_speed: float = 50.0
@export var wander_range: float = 100.0

var _target_position: Vector2


func _init() -> void:
    state_id = EnemyStateId.WANDER


func _enter() -> void:
    # Wander around anchor_position (set to group spawn_pivot at spawn time).
    var dir := Vector2.RIGHT.rotated(randf() * TAU)
    var min_dist = wander_range * 0.25
    var dist: float = min(randf() * wander_range + min_dist, wander_range)
    _target_position = enemy.anchor_position + dir * dist

    enemy.play_animation(Actor.ANIM_MOVE)
    enemy.navigation_finished.connect(_on_navigation_finished, CONNECT_ONE_SHOT)


func _exit() -> void:
    if enemy.navigation_finished.is_connected(_on_navigation_finished):
        enemy.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
    if enemy.is_player_in_aggro_range():
        change_state(EnemyStateId.CHASE)
        return

    enemy.move_to_position(_target_position, wander_speed, 5.0)

    var vel := enemy.get_path_velocity()
    if vel.length() > 0.1:
        enemy.set_facing_direction(vel, Actor.ANIM_MOVE)


func _on_navigation_finished() -> void:
    change_state(EnemyStateId.IDLE)
