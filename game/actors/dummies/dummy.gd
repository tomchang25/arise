@tool
class_name Dummy
extends CharacterBody2D

@export var stats: Stats
@export var hurtbox: Hurtbox
@export var damage_receiver: DamageReceiverModule
@export var health_bar: HealthBarModule

@export_group("Testbed")
@export var reset_on_death := true
@export var reset_delay := 0.5

var _spawn_pos: Vector2


func _ready() -> void:
    _spawn_pos = global_position

    _auto_wire_nodes()
    _ensure_stats()
    _bind_modules()


func _physics_process(_delta: float) -> void:
    move_and_slide()


func _auto_wire_nodes() -> void:
    if not hurtbox:
        hurtbox = find_child("Hurtbox", true, false) as Hurtbox
    if not damage_receiver:
        damage_receiver = find_child("DamageReceiverModule", true, false) as DamageReceiverModule
    if not health_bar:
        health_bar = find_child("HealthBar", true, false) as HealthBarModule


func _ensure_stats() -> void:
    if stats:
        stats.setup_stats()
        return

    stats = Stats.new()
    stats.faction = Stats.Faction.ENEMY
    stats.base_max_health = 200
    stats.base_defense = 0
    stats.base_damage = 0
    stats.setup_stats()


func _bind_modules() -> void:
    # Hurtbox needs owner_stats for collision layers (optional but nice)
    if hurtbox:
        hurtbox.owner_stats = stats

    # Damage receiver setup
    if damage_receiver:
        damage_receiver.stats = stats
        damage_receiver.hurtbox = hurtbox
        if not damage_receiver.died.is_connected(_on_died):
            damage_receiver.died.connect(_on_died)

    # Health bar bind
    if health_bar:
        health_bar.bind(stats)


func heal(amount: float) -> void:
    if not stats:
        return
    stats.health = min(stats.health + amount, stats.current_max_health)


func reset_dummy() -> void:
    if not stats:
        return
    global_position = _spawn_pos
    stats.health = stats.current_max_health


func _on_died(_info: AttackInfo) -> void:
    if not reset_on_death:
        return
    await get_tree().create_timer(max(0.0, reset_delay)).timeout
    reset_dummy()
