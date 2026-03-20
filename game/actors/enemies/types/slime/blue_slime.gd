## BlueSlime enemy.
## Uses a contact (attached hitbox) for damage.
## AI: Idle → Chase when detected (always tries to make contact) →
##     Contact attack in reach. Home position is force-updated to the
##     player every 10 seconds to prevent the leash from blocking re-engagement.
@tool
class_name BlueSlime
extends Enemy

const HOME_UPDATE_INTERVAL := 3.0

var _home_update_timer := 0.0

func _ready() -> void:
    if Engine.is_editor_hint():
        return

    actor_type = ActorType.BLUE_SLIME

    _auto_wire_nodes()

    # Wire the contact hitbox into the CombatModule's hitbox_slots BEFORE
    # _apply_data() calls setup() — WeaponExecutor binds slots at setup time.
    var contact_hitbox := find_child("ContactHitbox", true, false) as Hitbox
    if contact_hitbox and combat_module:
        combat_module.hitbox_slots = [contact_hitbox]

    _apply_data()
    _bind_modules()

    if home_position == Vector2.ZERO:
        push_warning("BlueSlime: home_position not set. Assign it at spawn time.")
    else:
        global_position = home_position
    
    activate_attack(0,0)

func _physics_process(delta: float) -> void:
    _home_update_timer += delta

    if _home_update_timer >= HOME_UPDATE_INTERVAL:
        _home_update_timer = 0.0
        var target := get_tree().get_first_node_in_group("player") as Node2D
        if target != null:
            home_position = target.global_position
