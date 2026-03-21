extends EnemyState

@export var back_speed: float = 50.0


func _init() -> void:
	state_id = EnemyStateId.LEASH_BACK


func _enter() -> void:
	enemy.play_animation(Actor.ANIM_MOVE)
	enemy.navigation_finished.connect(_on_navigation_finished, CONNECT_ONE_SHOT)


func _exit() -> void:
	if enemy.navigation_finished.is_connected(_on_navigation_finished):
		enemy.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
	enemy.move_to_position(enemy.anchor_position, back_speed, 5.0)

	var vel := enemy.get_path_velocity()
	if vel.length() > 0.1:
		enemy.set_facing_direction(vel, Actor.ANIM_MOVE)


func _on_navigation_finished() -> void:
	change_state(EnemyStateId.IDLE)
