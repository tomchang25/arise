## BlueSkull enemy.
## Uses a projectile orb attack at range.
## AI: Idle → Chase when detected → Retreat if player too close (< 50% reach radius,
##     back off until 90%) → Ranged attack when in reach.
## Home position is force-updated to the player every 10 seconds.
@tool
class_name BlueSkull
extends Enemy

## Effective attack range for the projectile weapon.
## Used to override the reach_detection radius since projectile definitions
## return 0 from get_attack_range() (only PlaceAttackDefinition returns a range).
@export var projectile_reach: float = 250.0


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    actor_type = ActorType.BLUE_SKULL

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()

    if home_position == Vector2.ZERO:
        push_warning("BlueSkull: home_position not set. Assign it at spawn time.")
    else:
        global_position = home_position


func _bind_reach_detection() -> void:
    if reach_detection == null:
        return
    # Projectile weapons return 0 from get_attack_range; set radius manually.
    reach_detection.set_collision_radius(projectile_reach)
