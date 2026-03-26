class_name Castle
extends Node2D

## Special dummy actor placed at (0, 0).
## High health pool, no AI.  Valid attack target for enemy FSMs via its Hurtbox.
## Added to the "castle" group on ready so other nodes can locate it easily.

signal died(context)

# -------------------------
# Exports — Modules
# -------------------------

@export_group("Modules — Combat")
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule
@export var hit_feedback: HitFeedbackModule
@export var damage_number: DamageNumberModule
@export var health_bar: HealthBarModule

# -------------------------
# Exports — Stats
# -------------------------

@export_group("Stats")
## Starting health pool.  Assign a large value to make the castle durable.
@export var max_health: float = 10000.0
@export var faction: Stats.Faction = Stats.Faction.PLAYER

# -------------------------
# Runtime state
# -------------------------

var stats: Stats

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    add_to_group(&"castle")
    _auto_wire_nodes()
    _setup_stats()
    _bind_modules()

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


func _setup_stats() -> void:
    stats = Stats.new()
    stats.faction = faction
    stats.base_max_health = max_health
    stats.setup_stats()


func _bind_modules() -> void:
    if hurtbox:
        hurtbox.owner_stats = stats

    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox

        if not damage_receiver.died.is_connected(_on_died):
            damage_receiver.died.connect(_on_died)

    if hit_feedback:
        hit_feedback.stats = stats
        hit_feedback.damage_receiver = damage_receiver

    if damage_number:
        damage_number.damage_receiver = damage_receiver

    if health_bar:
        health_bar.bind(stats)

# -------------------------
# Callbacks
# -------------------------


func _on_died(context) -> void:
    died.emit(context)
