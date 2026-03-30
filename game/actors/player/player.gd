@tool
class_name Player
extends CharacterBody2D

signal roll_finished
signal attack_finished
signal died(info)

# -------------------------
# Animation state constants
# -------------------------

const ANIM_IDLE: StringName = &"Idle"
const ANIM_MOVE: StringName = &"Move"
const ANIM_ROLL: StringName = &"Roll"
const ANIM_ATTACK: StringName = &"Attack"

# -------------------------
# Data
# -------------------------

@export var data: PlayerData

# -------------------------
# Modules — Visuals
# -------------------------

@export_group("Modules — Visuals")
@export var sprite: Sprite2D

# -------------------------
# Modules — Combat
# -------------------------

@export_group("Modules — Combat")
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule
@export var hit_feedback: HitFeedbackModule
@export var damage_number: DamageNumberModule
@export var health_bar: HealthBarModule
@export var combat_module: CombatModule

# -------------------------
# Modules — Perception
# -------------------------

@export_group("Modules — Perception")
## Detects enemies within attack range — used to auto-target nearest enemy.
@export var reach_detection: DetectionModule

# -------------------------
# Modules — Movement
# -------------------------

@export_group("Modules — Movement")
@export var movement_module: MovementModule
@export var animation_module: AnimationModule

# -------------------------
# Modules — Gameplay
# -------------------------

@export_group("Modules — Gameplay")
@export var pickup_collector: PickupCollectorModule

# -------------------------
# Modules — Framework
# -------------------------

@export_group("Modules — Framework")
@export var state_machine: StateMachine

# -------------------------
# Runtime state
# -------------------------

var stats: Stats

var _dodge_requested := false

# -------------------------
# Lifecycle
# -------------------------


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire_nodes()


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()

    queue_redraw()

    push_warning("Player: has_auto_attack_target is disabled. Make sure to uncomment it if you need it.")


func _draw() -> void:
    if not combat_module or Engine.is_editor_hint():
        return
    # Draw range ring for weapon 0, attack 0 as a debug guide.
    var attack_range := combat_module.get_attack_range(0, 0)
    if attack_range > 0.0:
        draw_arc(combat_module.global_position, attack_range, 0, TAU, 64, Color(0, 1, 0), 2.0)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("dodge"):
        _dodge_requested = true

# -------------------------
# Data application
# -------------------------


func _apply_data() -> void:
    if data == null:
        push_error("Player: no PlayerData assigned — using fallback stats.")
        return

    # Duplicate so each instance owns its own runtime stats.
    if data.stats:
        stats = data.stats.duplicate() as Stats
    _ensure_stats()

    # Initialize combat module — stats and weapons must always be set together.
    if combat_module:
        combat_module.setup(stats, data.weapons)

    if pickup_collector:
        pickup_collector.magnet_range = data.magnet_range

    # Listen for runtime inspector changes to debug flags.
    if not data.debug_modes_changed.is_connected(_enforce_debug_modes):
        data.debug_modes_changed.connect(_enforce_debug_modes)

    if stats and not stats.stats_recalculated.is_connected(_on_stats_recalculated):
        stats.stats_recalculated.connect(_on_stats_recalculated)


func _ensure_stats() -> void:
    if stats:
        stats.setup_stats()
        return

    stats = Stats.new()
    stats.faction = Stats.Faction.PLAYER
    stats.setup_stats()

# -------------------------
# Module wiring
# -------------------------


func _auto_wire_nodes() -> void:
    if not sprite:
        sprite = find_child("Sprite", true, false) as Sprite2D
    if not hurtbox:
        hurtbox = find_child("Hurtbox", true, false) as Hurtbox
    if not damage_receiver:
        damage_receiver = find_child("DamageReceiverModule", true, false) as DamageReceiverModule
    if not hit_feedback:
        hit_feedback = find_child("HitFeedbackModule", true, false) as HitFeedbackModule
    if not damage_number:
        damage_number = find_child("DamageNumberModule", true, false) as DamageNumberModule
    if not health_bar:
        health_bar = find_child("HealthBar", true, false) as HealthBarModule
    if not combat_module:
        combat_module = find_child("CombatModule", true, false) as CombatModule
    if not reach_detection:
        reach_detection = find_child("ReachDetection", true, false) as DetectionModule
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule
    if not animation_module:
        animation_module = find_child("AnimationModule", true, false) as AnimationModule
    if not pickup_collector:
        pickup_collector = find_child("PickupCollectorModule", true, false) as PickupCollectorModule
    if not state_machine:
        state_machine = find_child("StateMachine", true, false) as StateMachine


func _bind_modules() -> void:
    # ── Movement ──────────────────────────────────────────────────────────
    if movement_module:
        movement_module.character = self
        movement_module.set_manual_mode()

    # ── Animation ─────────────────────────────────────────────────────────
    if animation_module:
        animation_module.actor = self

    # ── Combat ────────────────────────────────────────────────────────────
    if hurtbox:
        hurtbox.owner_stats = stats

    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox

        if not Engine.is_editor_hint():
            if not damage_receiver.damaged.is_connected(_on_damaged):
                damage_receiver.damaged.connect(_on_damaged)
            if not damage_receiver.died.is_connected(_on_died):
                damage_receiver.died.connect(_on_died)

    if hit_feedback:
        hit_feedback.stats = stats
        hit_feedback.damage_receiver = damage_receiver

    if damage_number:
        damage_number.damage_receiver = damage_receiver

    if health_bar:
        health_bar.bind(stats)

    # ── Perception (reach) ────────────────────────────────────────────────
    _refresh_reach_range()

    # ── Pickup collector ──────────────────────────────────────────────────
    if pickup_collector:
        pickup_collector.owner_body = self
        pickup_collector.stats = stats
        if has_method("add_item"):
            pickup_collector.inventory_owner = self

    # ── Animation signals ─────────────────────────────────────────────────
    if animation_module and not animation_module.animation_finished.is_connected(_on_animation_finished):
        animation_module.animation_finished.connect(_on_animation_finished)

    # ── Debug modes ───────────────────────────────────────────────────────
    _enforce_debug_modes()


## Update reach_detection radius from the effective range of weapon 0, attack 0.
func _refresh_reach_range() -> void:
    if reach_detection == null or combat_module == null:
        return

    var attack_range := combat_module.get_attack_range(0, 0)
    if attack_range > 0.0:
        reach_detection.set_collision_radius(attack_range)

# -------------------------
# Debug modes — runtime enforcement
# -------------------------


## Apply god-mode range override across all weapons and attacks on the combat module.
## Called on ready and after every stats recalculation.
func _enforce_debug_modes() -> void:
    if Engine.is_editor_hint():
        return
    if data == null or combat_module == null:
        return

    if data.is_max_range_active():
        var r := data.god_attack_range_override
        for wi in combat_module.get_weapon_count():
            for ai in combat_module.get_attack_count(wi):
                combat_module.set_attack_range_override(wi, ai, r)
    else:
        combat_module.clear_all_range_overrides()

# -------------------------
# Damage / death callbacks
# -------------------------


func _on_damaged(amount: float, _new_health: float, _info) -> void:
    # God mode — no damage: undo what DamageReceiverModule already subtracted.
    if data and data.is_no_damage_active():
        stats.health = min(stats.health + amount, stats.current_max_health)
        return

    # Undead mode — clamp health floor to 1.
    if data and data.undead_mode:
        if stats.health < 1.0:
            stats.health = 1.0

    if sprite and sprite.material and stats:
        var ratio := (1.0 - (stats.health / stats.current_max_health)) * 0.5
        sprite.material.set_shader_parameter("overlay_amount", ratio)


func _on_died(info) -> void:
    # Undead / god — refuse death and restore 1 HP.
    if data and (data.undead_mode or data.is_no_damage_active()):
        stats.health = 1.0
        return

    died.emit(info)

# -------------------------
# Stats callbacks
# -------------------------


func _on_stats_recalculated() -> void:
    _enforce_debug_modes()
    _refresh_reach_range()
    queue_redraw()

# -------------------------
# Animation callback
# -------------------------


func _on_animation_finished(anim_name: StringName) -> void:
    var anim_text := String(anim_name)
    if String(ANIM_ROLL) in anim_text:
        roll_finished.emit()
    elif String(ANIM_ATTACK) in anim_text:
        attack_finished.emit()

# -------------------------
# Public API — input helpers
# -------------------------


func get_move_input() -> Vector2:
    return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func is_run_pressed() -> bool:
    return Input.is_action_pressed("run")


func consume_attack_request() -> bool:
    return can_attack() and Input.is_action_pressed("attack")


func consume_dodge_request() -> bool:
    var requested := _dodge_requested
    _dodge_requested = false
    return requested

# -------------------------
# Public API — movement
# -------------------------


## Stop all active manual motion.
func stop_movement() -> void:
    if movement_module:
        movement_module.stop_manual_motion()


## Drive the player body in a direction at a given speed.
func set_movement_velocity(direction: Vector2, speed: float) -> void:
    if movement_module:
        movement_module.set_manual_mode()
        movement_module.set_manual_velocity(direction.normalized() * speed)


func apply_knockback(impulse: Vector2) -> void:
    if movement_module:
        movement_module.apply_knockback(impulse)

# -------------------------
# Public API — animation
# -------------------------


## Travel to an animation state and optionally set time scale.
func play_animation(state_name: StringName, time_scale: float = 1.0) -> void:
    if animation_module == null:
        return
    animation_module.travel(state_name)
    animation_module.set_time_scale(time_scale)


## Set facing direction and blend-space position for a state.
func set_facing_direction(direction: Vector2, state_name: StringName) -> void:
    if animation_module == null:
        return
    animation_module.face_direction(direction)
    animation_module.set_blend_position(direction, state_name)

# -------------------------
# Public API — combat
# -------------------------


func get_attack_origin() -> Vector2:
    if combat_module:
        return combat_module.global_position
    return global_position


func can_attack(weapon_index: int = 0, attack_index: int = 0) -> bool:
    if combat_module == null:
        return false
    return combat_module.can_attack(weapon_index, attack_index)


## Perform an attack.
## weapon_index and attack_index map directly to CombatModule's weapon/attack arrays.
## Defaults to weapon 0, attack 0 — the primary attack of the equipped weapon.
func perform_attack(target_pos: Vector2, weapon_index: int = 0, attack_index: int = 0) -> void:
    if combat_module == null:
        return

    combat_module.perform_attack(weapon_index, attack_index, target_pos)


## Signal the combat module that an animation-driven attack has finished
## and the cooldown should now start.
func end_attack(weapon_index: int = 0, attack_index: int = 0) -> void:
    if combat_module == null:
        return
    combat_module.end_attack(weapon_index, attack_index)


## Returns the effective attack range for a given weapon / attack slot.
## Reflects any active range override (god mode, buffs).
## Defaults to weapon 0, attack 0.
func get_attack_range(weapon_index: int = 0, attack_index: int = 0) -> float:
    if combat_module == null:
        return 0.0
    return combat_module.get_attack_range(weapon_index, attack_index)


## Set a runtime range override for a specific weapon/attack.
## Does not modify the WeaponData or AttackDefinition resource.
## Useful for buffs, debuffs, or temporary ability changes.
func set_attack_range_override(weapon_index: int, attack_index: int, range_value: float) -> void:
    if combat_module == null:
        return
    combat_module.set_attack_range_override(weapon_index, attack_index, range_value)
    _refresh_reach_range()


## Remove a range override for a specific weapon/attack, restoring its base value.
func clear_attack_range_override(weapon_index: int, attack_index: int) -> void:
    if combat_module == null:
        return
    combat_module.clear_attack_range_override(weapon_index, attack_index)
    _refresh_reach_range()


## Remove all range overrides, restoring all base AttackDefinition values.
func clear_all_range_overrides() -> void:
    if combat_module == null:
        return
    combat_module.clear_all_range_overrides()
    _refresh_reach_range()

# -------------------------
# Public API — perception proxies
# -------------------------


## True when at least one enemy is inside attack range.
func has_target_in_reach() -> bool:
    if reach_detection == null:
        return false
    return reach_detection.get_target_count(false) > 0


## Closest enemy inside attack range, or null.
func get_nearest_reachable_target() -> Node2D:
    if reach_detection == null:
        return null
    return reach_detection.get_closest_target(false)


## True when there is a valid target in reach.
func has_auto_attack_target() -> bool:
    # \return false
    return can_attack() and is_instance_valid(get_nearest_reachable_target())

# -------------------------
# Public API — aim helpers
# -------------------------


func get_attack_target_position(weapon_index: int = 0, attack_index: int = 0) -> Vector2:
    var attack_range := get_attack_range(weapon_index, attack_index)
    var origin := get_attack_origin()
    var target := get_nearest_reachable_target()

    if is_instance_valid(target):
        var to_target := target.global_position - origin
        if attack_range <= 0.0:
            return origin
        if to_target.length() <= attack_range:
            return target.global_position
        if to_target == Vector2.ZERO:
            return origin
        return origin + to_target.normalized() * attack_range

    var mouse_pos := get_global_mouse_position()
    var to_mouse := mouse_pos - origin
    if attack_range <= 0.0:
        return origin
    if to_mouse.length() <= attack_range:
        return mouse_pos
    if to_mouse == Vector2.ZERO:
        return origin + Vector2.DOWN * attack_range
    return origin + to_mouse.normalized() * attack_range


func get_aim_direction() -> Vector2:
    var origin := get_attack_origin()
    var target := get_nearest_reachable_target()

    if is_instance_valid(target):
        var to_target := target.global_position - origin
        if to_target != Vector2.ZERO:
            return to_target.normalized()

    var to_mouse := get_global_mouse_position() - origin
    if to_mouse != Vector2.ZERO:
        return to_mouse.normalized()

    var move_input := get_move_input()
    if move_input != Vector2.ZERO:
        return move_input.normalized()

    if animation_module:
        return animation_module.get_last_direction()

    return Vector2.DOWN

# -------------------------
# Public API — pickup collector
# -------------------------


func get_pickup_collector_module() -> PickupCollectorModule:
    return pickup_collector

# -------------------------
# Public API — misc
# -------------------------


func reset() -> void:
    velocity = Vector2.ZERO
    _dodge_requested = false

    if data and data.stats:
        stats = data.stats.duplicate() as Stats
        _ensure_stats()
        if not data.debug_modes_changed.is_connected(_enforce_debug_modes):
            data.debug_modes_changed.connect(_enforce_debug_modes)
        if not stats.stats_recalculated.is_connected(_on_stats_recalculated):
            stats.stats_recalculated.connect(_on_stats_recalculated)
        if hurtbox:
            hurtbox.owner_stats = stats
        if damage_receiver:
            damage_receiver.stats = stats
        if hit_feedback:
            hit_feedback.stats = stats
        if health_bar:
            health_bar.bind(stats)
        if combat_module:
            combat_module.setup(stats, data.weapons)
        if pickup_collector:
            pickup_collector.stats = stats

    if hurtbox:
        hurtbox.reset()
    if damage_receiver:
        damage_receiver.reset()
    if hit_feedback:
        hit_feedback.reset()
    if damage_number:
        damage_number.reset()
    if health_bar:
        health_bar.reset()
    if combat_module:
        combat_module.reset()
    if reach_detection:
        reach_detection.reset()
    if movement_module:
        movement_module.reset()
    if animation_module:
        animation_module.reset()
    if pickup_collector:
        pickup_collector.reset()


func set_enabled(value: bool) -> void:
    if hurtbox:
        hurtbox.set_enabled(value)
    if damage_receiver:
        damage_receiver.set_enabled(value)
    if hit_feedback:
        hit_feedback.set_enabled(value)
    if damage_number:
        damage_number.set_enabled(value)
    if health_bar:
        health_bar.set_enabled(value)
    if combat_module:
        combat_module.set_enabled(value)
    if reach_detection:
        reach_detection.set_enabled(value)
    if movement_module:
        movement_module.set_enabled(value)
    if animation_module:
        animation_module.set_enabled(value)
    if pickup_collector:
        pickup_collector.set_enabled(value)


func reset_position(new_position: Vector2) -> void:
    global_position = new_position
    if state_machine:
        state_machine.reset_to_initial()
