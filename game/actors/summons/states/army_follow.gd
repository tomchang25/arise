extends ArmyState

@export var animation_state: StringName = Actor.ANIM_MOVE
@export var move_speed: float = 100
@export var min_distance_to_anchor: float = 25


func _init() -> void:
    state_id = ArmyStateId.FOLLOW


func _enter() -> void:
    target.play_animation(animation_state)


func _update(_delta: float) -> void:
    # Navigate to the formation slot (anchor_position is updated each frame by ArmyHandler).
    target.move_to_position(target.anchor_position, move_speed, 5)

    # Update animation based on pathfinding velocity.
    var velocity = target.get_path_velocity()
    target.set_facing_direction(velocity, animation_state)

    # Re-engage nearby enemies when close enough to the formation slot.
    if target.get_distance_to_anchor() < min_distance_to_anchor:
        if target.is_target_tracked():
            change_state(ArmyStateId.CHASE)
            return

    if target.is_navigation_finished():
        change_state(ArmyStateId.IDLE)
        return
