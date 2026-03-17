class_name CombatTestActor
extends CharacterBody2D

## Sandbox test actor for verifying the combat system.
## No state machine — input drives CombatModule directly each frame.
##
## Weapon layout (set via CombatModule.weapons in the scene):
##   weapons[0]  — fire weapon  (attacks[0] = melee/slash, attacks[1] = projectile)
##   weapons[1]  — charge weapon (attacks[0] = charge hitbox)
##   weapons[2]  — contact weapon (attacks[0] = contact body hitbox, always active)

# -------------------------
# Input actions
# -------------------------

const ACTION_CHARGE := &"test_charge"

# -------------------------
# Exports
# -------------------------

@export_group("Modules")
@export var movement_module: MovementModule
@export var combat_module: CombatModule
@export var reach_detection: DetectionModule

@export_group("Movement")
@export var walk_speed: float = 180.0
@export var run_speed: float = 280.0

@export_group("Weapon Indices")
## Index of the fire weapon (slash + projectile) in CombatModule.weapons.
@export var fire_weapon_index: int = 0
## Index of the charge weapon in CombatModule.weapons.
@export var charge_weapon_index: int = 1
## Index of the contact (body) weapon in CombatModule.weapons.
@export var contact_weapon_index: int = 2

# -------------------------
# Runtime state
# -------------------------

var stats: Stats

var _charge_active: bool = false
var _last_aim_dir: Vector2 = Vector2.DOWN

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _auto_wire_nodes()
    _setup_stats()
    _bind_modules()
    _ensure_actions()

    # Contact attack is always active — it's a persistent body hitbox.
    combat_module.activate_attack(contact_weapon_index, 0)


func _auto_wire_nodes() -> void:
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule
    if not combat_module:
        combat_module = find_child("CombatModule", true, false) as CombatModule
    if not reach_detection:
        reach_detection = find_child("ReachDetection", true, false) as DetectionModule


func _setup_stats() -> void:
    stats = Stats.new()
    stats.faction = Stats.Faction.PLAYER
    stats.base_damage = 100.0
    stats.setup_stats()


func _bind_modules() -> void:
    if movement_module:
        movement_module.character = self
        movement_module.set_manual_mode()

    if combat_module:
        combat_module.stats = stats

    if reach_detection:
        var attac_range := combat_module.get_attack_range(fire_weapon_index, 0) if combat_module else 50.0
        if attac_range > 0.0:
            reach_detection.set_collision_radius(attac_range)


# -------------------------
# Per-frame input
# -------------------------


func _physics_process(_delta: float) -> void:
    _handle_movement()
    _handle_charge_toggle()


func _unhandled_input(event: InputEvent) -> void:
    # LMB — slash (fire weapon, attack 0)
    if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
        if (event as InputEventMouseButton).pressed:
            _fire_attack(fire_weapon_index, 0)

    # RMB — projectile (fire weapon, attack 1)
    elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_RIGHT:
        if (event as InputEventMouseButton).pressed:
            _fire_attack(fire_weapon_index, 1)


func _handle_movement() -> void:
    if movement_module == null:
        return

    var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    var speed := run_speed if Input.is_action_pressed("run") else walk_speed

    if input_dir != Vector2.ZERO:
        movement_module.set_move_direction(input_dir, speed)
        _last_aim_dir = input_dir
    else:
        movement_module.stop_manual_motion()


func _handle_charge_toggle() -> void:
    if combat_module == null:
        return

    var want_charge := Input.is_action_pressed(ACTION_CHARGE)

    if want_charge and not _charge_active:
        _charge_active = true
        combat_module.activate_attack(charge_weapon_index, 0)
        combat_module.set_weapon_enabled(fire_weapon_index, false)
        combat_module.set_weapon_enabled(contact_weapon_index, false)
        print("TEST1")
    elif not want_charge and _charge_active:
        _charge_active = false
        combat_module.deactivate_attack(charge_weapon_index, 0)
        combat_module.set_weapon_enabled(fire_weapon_index, true)
        combat_module.set_weapon_enabled(contact_weapon_index, true)
        print("TEST2")


# -------------------------
# Internal helpers
# -------------------------


func _fire_attack(weapon_index: int, attack_index: int) -> void:
    if combat_module == null:
        return
    if not combat_module.can_attack(weapon_index, attack_index):
        return

    var target_pos := _get_target_position(weapon_index, attack_index)
    combat_module.perform_attack(weapon_index, attack_index, target_pos, true)


func _get_target_position(weapon_index: int, attack_index: int) -> Vector2:
    var attac_range := combat_module.get_attack_range(weapon_index, attack_index)
    var origin := global_position
    var mouse_pos := get_global_mouse_position()

    # Prefer nearest enemy in reach over raw mouse position.
    if reach_detection:
        var nearest := reach_detection.get_closest_target(false)
        if is_instance_valid(nearest):
            var to_target := nearest.global_position - origin
            if attac_range <= 0.0 or to_target.length() <= attac_range:
                return nearest.global_position
            return origin + to_target.normalized() * attac_range

    var to_mouse := mouse_pos - origin
    if attac_range <= 0.0:
        return mouse_pos
    if to_mouse.length() <= attac_range:
        return mouse_pos
    return origin + to_mouse.normalized() * attac_range


func _get_aim_direction() -> Vector2:
    var to_mouse := get_global_mouse_position() - global_position
    if to_mouse.length_squared() > 0.01:
        return to_mouse.normalized()

    if _last_aim_dir != Vector2.ZERO:
        return _last_aim_dir.normalized()

    return Vector2.RIGHT


# -------------------------
# Action registration
# -------------------------


func _ensure_actions() -> void:
    _ensure_key_action(ACTION_CHARGE, KEY_R)


func _ensure_key_action(action: StringName, keycode: Key) -> void:
    if InputMap.has_action(action):
        return
    InputMap.add_action(action)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action, event)


# -------------------------
# Public API
# -------------------------


func reset_position(pos: Vector2) -> void:
    global_position = pos
    if _charge_active:
        _charge_active = false
        if combat_module:
            combat_module.deactivate_attack(charge_weapon_index, 0)
