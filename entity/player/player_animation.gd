# player_animation_component.gd
class_name PlayerAnimation
extends BaseAnimation

# Player-specific animation state constants
const ANIMATION_STATE_IDLE = "Idle"
const ANIMATION_STATE_MOVE = "Move"
const ANIMATION_STATE_RUN = "Run"
const ANIMATION_STATE_ATTACK = "Attack"
const ANIMATION_STATE_ROLL = "Roll"

# Array of player-specific animation states
const PLAYER_ANIMATION_STATES: Array[String] = [ANIMATION_STATE_IDLE, ANIMATION_STATE_MOVE, ANIMATION_STATE_RUN, ANIMATION_STATE_ATTACK, ANIMATION_STATE_ROLL]


func _ready():
    # 1. Provide the specific states to the base component
    set_animation_states(PLAYER_ANIMATION_STATES)

    # 2. Call the base class _ready to connect the AnimationTree signal
    super._ready()
