extends ArmyState

@export var follow_threshold: float = 50
@export var animation_state: StringName = Actor.ANIM_IDLE


func _init() -> void:
	state_id = ArmyStateId.IDLE


func _enter() -> void:
	target.stop_movement()
	target.play_animation(animation_state)


func _update(_delta: float) -> void:
	if target.get_distance_to_anchor() > follow_threshold:
		change_state(ArmyStateId.FOLLOW)
		return

	if target.is_target_tracked():
		change_state(ArmyStateId.CHASE)
		return
