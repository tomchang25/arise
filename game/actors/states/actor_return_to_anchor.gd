## Shared return-to-anchor state for all actors.
##
## Moves the actor back toward anchor_position. Unifies what was previously:
##   - Army's FOLLOW state  (navigate to player formation slot)
##   - Enemy's BACK state   (return home after deaggro)
##   - Enemy's LEASH_BACK state (forced return when leash exceeded)
##
## Transitions:
##   → IDLE   when navigation finishes (arrived at anchor)
##   → CHASE  if a target re-enters the detection zone while returning
extends ActorState

@export var back_speed: float = 50.0

## When > 0, the actor only re-engages targets after it has come within this
## distance of its anchor. Set to INF to allow re-engagement from anywhere.
## INF is appropriate for enemies (has_deaggro); a small value for army units.
@export var re_engage_distance: float = INF

## Timeout check
@export var return_timeout: float = 10.0

## Minimum distance (units/sec) the actor must be moving to skip force-arrive
## when the timeout fires. If the actor is making meaningful progress it gets
## another full timeout window instead of being teleported.
@export var min_progress_speed: float = 15.0

var _elapsed: float = 0.0

## Accumulated displacement over the current timeout window, sampled each frame.
var _window_distance: float = 0.0
var _last_position: Vector2 = Vector2.ZERO


func _init() -> void:
    state_id = ActorStateId.RETURN_TO_ANCHOR


func _enter() -> void:
    actor.play_animation(Actor.ANIM_MOVE)
    _elapsed = 0.0
    _window_distance = 0.0
    _last_position = actor.global_position
    actor.navigation_finished.connect(_on_navigation_finished, CONNECT_ONE_SHOT)


func _exit() -> void:
    if actor.navigation_finished.is_connected(_on_navigation_finished):
        actor.navigation_finished.disconnect(_on_navigation_finished)


func _update(delta: float) -> void:
    actor.move_to_position(actor.anchor_position, back_speed, 5.0)

    var vel := actor.get_path_velocity()
    if vel.length() > 0.1:
        actor.set_facing_direction(vel, Actor.ANIM_MOVE)

    # Accumulate displacement for progress tracking.
    _window_distance += actor.global_position.distance_to(_last_position)
    _last_position = actor.global_position

    # Re-engage check
    var dist_to_anchor := actor.get_distance_to_anchor()
    if dist_to_anchor <= re_engage_distance and actor.is_aggro_active():
        change_state(ActorStateId.CHASE)
        return

    # Timeout
    if return_timeout > 0.0:
        _elapsed += delta
        if _elapsed >= return_timeout:
            # Skip force-arrive if the actor is making meaningful progress.
            var speed_this_window := _window_distance / _elapsed
            if speed_this_window >= min_progress_speed:
                # Still moving — give another full window.
                _elapsed = 0.0
                _window_distance = 0.0
                _last_position = actor.global_position
                return
            _force_arrive()
            return


func _on_navigation_finished() -> void:
    change_state(ActorStateId.IDLE)


func _force_arrive() -> void:
    actor.global_position = actor.anchor_position
    change_state(ActorStateId.IDLE)
