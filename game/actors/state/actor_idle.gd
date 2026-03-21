## Shared idle state for all actors.
##
## Behaviour depends on ActorData flags:
##   has_wander  → transitions to WANDER when the idle timer expires
##   (no flag)   → stays idle until a target or distance threshold triggers a change
##
## Transitions:
##   → RETURN_TO_ANCHOR  if actor is too far from anchor_position
##   → CHASE             if a target enters the aggro detection zone
##   → WANDER            if has_wander and idle timer expires
extends ActorState

@export var anchor_threshold: float = 50.0
@export var min_idle_time: float = 2.0
@export var max_idle_time: float = 5.0

var _idle_timer: float = 0.0
var _wait_time: float = 0.0


func _init() -> void:
	state_id = ActorStateId.IDLE


func _enter() -> void:
	actor.stop_movement()
	actor.play_animation(Actor.ANIM_IDLE)

	if _has_wander():
		_wait_time = randf_range(min_idle_time, max_idle_time)
		_idle_timer = 0.0


func _update(delta: float) -> void:
	# Too far from anchor → return
	if actor.get_distance_to_anchor() > anchor_threshold:
		change_state(ActorStateId.RETURN_TO_ANCHOR)
		return

	# Target enters aggro zone → chase
	if _is_aggro_triggered():
		change_state(ActorStateId.CHASE)
		return

	# Wander when idle timer expires (enemy behaviour)
	if _has_wander():
		_idle_timer += delta
		if _idle_timer >= _wait_time:
			change_state(ActorStateId.WANDER)

# -------------------------
# Internal helpers
# -------------------------


## Returns true when the primary detection zone has at least one target.
## For Army: track_detection; for Enemy: aggro_detection.
func _is_aggro_triggered() -> bool:
	var army := actor as Army
	if army:
		return army.is_target_tracked()

	var enemy := actor as Enemy
	if enemy:
		return enemy.is_player_in_aggro_range()

	return false


func _has_wander() -> bool:
	var army := actor as Army
	if army and army.data:
		return army.data.has_wander

	var enemy := actor as Enemy
	if enemy and enemy.data:
		return enemy.data.has_wander

	return false
