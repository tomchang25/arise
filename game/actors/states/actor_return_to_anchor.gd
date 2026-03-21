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


func _init() -> void:
    state_id = ActorStateId.RETURN_TO_ANCHOR


func _enter() -> void:
    actor.play_animation(Actor.ANIM_MOVE)
    actor.navigation_finished.connect(_on_navigation_finished, CONNECT_ONE_SHOT)


func _exit() -> void:
    if actor.navigation_finished.is_connected(_on_navigation_finished):
        actor.navigation_finished.disconnect(_on_navigation_finished)


func _update(_delta: float) -> void:
    actor.move_to_position(actor.anchor_position, back_speed, 5.0)

    var vel := actor.get_path_velocity()
    if vel.length() > 0.1:
        actor.set_facing_direction(vel, Actor.ANIM_MOVE)

    # Re-engage if a target appears (within the allowed re-engage range).
    var dist_to_anchor := actor.get_distance_to_anchor()
    if dist_to_anchor <= re_engage_distance and _is_aggro_triggered():
        change_state(ActorStateId.CHASE)


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
