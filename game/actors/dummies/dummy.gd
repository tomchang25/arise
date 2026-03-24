@tool
class_name Dummy
extends CharacterBody2D

signal died(context: EffectContext)

# -------------------------
# Exports
# -------------------------

@export var data: EnemyData

@export_group("Modules — Combat")
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule
@export var hit_feedback: HitFeedbackModule
@export var damage_number: DamageNumberModule
@export var health_bar: HealthBarModule
@export var combat_module: CombatModule

@export_group("Modules — Movement")
@export var movement_module: MovementModule

@export_group("Testbed")
@export var reset_on_death := true
@export var reset_delay := 0.5

# -------------------------
# Runtime state
# -------------------------

var stats: Stats
var _spawn_pos: Vector2

# -------------------------
# Lifecycle
# -------------------------


func _enter_tree() -> void:
    if Engine.is_editor_hint():
        _auto_wire_nodes()
        _bind_modules()


func _ready() -> void:
    if Engine.is_editor_hint():
        return

    _spawn_pos = global_position

    _auto_wire_nodes()
    _apply_data()
    _bind_modules()
    _inject_stats_events()


func _physics_process(_delta: float) -> void:
    move_and_slide()

# -------------------------
# Setup
# -------------------------


func _auto_wire_nodes() -> void:
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
    if not movement_module:
        movement_module = find_child("MovementModule", true, false) as MovementModule


func _apply_data() -> void:
    if not data:
        push_error("Dummy has no data.")
        return
    stats = data.stats.duplicate()
    _ensure_stats()

    # Load weapons from data into combat module if provided.
    if combat_module and data.weapons.size() > 0:
        combat_module.equip_weapons(data.weapons)


func _ensure_stats() -> void:
    if not stats:
        push_error("Dummy has no stats.")
        return

    stats.setup_stats()


func _bind_modules() -> void:
    if damage_receiver:
        damage_receiver.hurtbox = hurtbox

    if hit_feedback:
        hit_feedback.damage_receiver = damage_receiver
        hit_feedback.movement_module = movement_module

    if damage_number:
        damage_number.damage_receiver = damage_receiver

    # --- Movement ---
    if movement_module:
        movement_module.character = self


func _inject_stats_events() -> void:
    if combat_module:
        combat_module.stats = stats

    if hurtbox:
        hurtbox.owner_stats = stats

    if damage_receiver:
        damage_receiver.stats = stats

        if not damage_receiver.died.is_connected(_on_died):
            damage_receiver.died.connect(_on_died)

    if hit_feedback:
        hit_feedback.stats = stats

    if health_bar:
        health_bar.bind(stats)

# -------------------------
# Public API
# -------------------------


func reset() -> void:
    global_position = _spawn_pos
    velocity = Vector2.ZERO

    if data:
        stats = data.stats.duplicate()
        _ensure_stats()
        if hurtbox:
            hurtbox.owner_stats = stats
        if damage_receiver:
            damage_receiver.stats = stats
        if hit_feedback:
            hit_feedback.stats = stats
        if health_bar:
            health_bar.bind(stats)
        if combat_module and data.weapons.size() > 0:
            combat_module.setup(stats, data.weapons)

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
    if movement_module:
        movement_module.reset()


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
    if movement_module:
        movement_module.set_enabled(value)


func heal(amount: float) -> void:
    if not stats:
        return
    stats.health = min(stats.health + amount, stats.current_max_health)


func reset_dummy() -> void:
    if not stats:
        return
    global_position = _spawn_pos
    stats.health = stats.current_max_health

# -------------------------
# Callbacks
# -------------------------


func _on_died(context: EffectContext) -> void:
    died.emit(context)

    if not reset_on_death:
        return
    await get_tree().create_timer(max(0.0, reset_delay)).timeout
    reset_dummy()

# const SLIME_DEATH_EXPLOSION = preload("uid://dvxy8nfvivevq")
# var def: PlaceAttackDefinition = SLIME_DEATH_EXPLOSION

# # Build the context — this is all you need to do
# var explosion_ctx := EffectContext.build(def, stats, self, global_position)
# if explosion_ctx == null:
#     return

# var action := SpawnPackedSceneAction.new()
# action.scene = def.attack_scene
# action.use_anchor_position = true

# var spawn_parent := get_parent()
# var spawn_ctx := SpawnContext.new()
# spawn_ctx.setup(spawn_parent, 0, self)

# var request := SpawnRequest.new()
# request.setup_direct(action, global_position, spawn_ctx)
# var result: SpawnResult = await request.execute()

# if result.success:
#     var delivery := result.spawned_node as AttackDelivery
#     if delivery and not delivery.is_node_ready():
#         await delivery.ready
#     delivery.setup(explosion_ctx)
#     delivery.trigger()
