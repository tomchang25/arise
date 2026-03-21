## Shared wander state — actors with has_wander=true roam near their anchor_position.
##
## Picks a random position within wander_range of anchor_position and navigates there.
##
## Transitions:
##   → CHASE  if a target enters the aggro detection zone while wandering
##   → IDLE   when navigation finishes
extends ActorState

@export var wander_speed: float = 50.0
@export var wander_range: float = 100.0

var _target_position: Vector2


func _init() -> void:
	state_id = ActorStateId.WANDER


func _enter() -> void:
	var dir := Vector2.RIGHT.rotated(randf() * TAU)
	var min_dist := wander_range * 0.25
	var dist: float = min(randf() * wander_range + min_dist, wander_range)
	_target_position = actor.anchor_position + dir * dist

	actor.play_animation(Actor.ANIM_MOVE)
	actor.navigation_finished.connect(_on_navigation_finished, CONNECT_ONE_SHOT)


func _exit() -> void:
	if actor.navigation_finished.is_connected(_on_navigation_finished):
		actor.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
	if _is_aggro_triggered():
		change_state(ActorStateId.CHASE)
		return

	actor.move_to_position(_target_position, wander_speed, 5.0)

	var vel := actor.get_path_velocity()
	if vel.length() > 0.1:
		actor.set_facing_direction(vel, Actor.ANIM_MOVE)


func _on_navigation_finished() -> void:
	change_state(ActorStateId.IDLE)

# -------------------------
# Internal helpers
# -------------------------


func _is_aggro_triggered() -> bool:
	var army := actor as Army
	if army:
		return army.is_target_tracked()
	var enemy := actor as Enemy
	if enemy:
		return enemy.is_player_in_aggro_range()
	return false
