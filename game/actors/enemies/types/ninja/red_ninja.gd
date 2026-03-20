## RedNinja enemy.
## Uses a slash (detached melee) attack.
## AI: Idle → Chase when detected → Slash attack when in reach.
## Home position is force-updated to the player every 10 seconds.
@tool
class_name RedNinja
extends Enemy

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    actor_type = ActorType.RED_NINJA

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()

    if home_position == Vector2.ZERO:
        push_warning("RedNinja: home_position not set. Assign it at spawn time.")
    else:
        global_position = home_position
