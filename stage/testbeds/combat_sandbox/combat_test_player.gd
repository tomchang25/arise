class_name CombatTestPlayer
extends CharacterBody2D

# -------------------------
# Exports
# -------------------------

@export_group("Modules")
@export var combat_module: CombatModule
@export var movement_module: MovementModule

@export_group("Movement")
@export var move_speed: float = 120.0

@export_group("Attack")
@export var primary_slot: Stats.AttackSlot = Stats.AttackSlot.PRIMARY
@export var secondary_slot: Stats.AttackSlot = Stats.AttackSlot.SECONDARY


# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    _auto_wire()


func _auto_wire() -> void:
    if not combat_module:
        combat_module = find_child("CombatModule", true, false) as CombatModule
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule


func _physics_process(_delta: float) -> void:
    _handle_movement()
    _handle_attack_input()
 

# -------------------------
# Input Handling
# -------------------------


func _handle_movement() -> void:
    if not movement_module:
        return

    var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if dir != Vector2.ZERO:
        movement_module.set_manual_mode()
        movement_module.set_manual_velocity(dir * move_speed)
    else:
        movement_module.stop_manual_motion()


func _handle_attack_input() -> void:
    if not combat_module:
        return

    var mouse_pos := get_global_mouse_position()

    if Input.is_action_just_pressed("mouse_left"):
        combat_module.perform_attack(primary_slot, mouse_pos, true)

    if Input.is_action_just_pressed("mouse_right"):
        combat_module.perform_attack(secondary_slot, mouse_pos, true)

    # Persistent attack: hold Q to activate contact, release to deactivate
    if Input.is_action_just_pressed("test_contact_attack"):
        var dir := global_position.direction_to(mouse_pos)
        combat_module.activate_attack(primary_slot, dir)

    if Input.is_action_just_released("test_contact_attack"):
        combat_module.deactivate_attack(primary_slot)


# -------------------------
# Public API
# -------------------------


func reset_position(spawn_pos: Vector2) -> void:
    global_position = spawn_pos
