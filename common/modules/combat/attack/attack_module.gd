class_name AttackModule
extends Node2D

@export var attack_cooldown: float = 0.5
@export var max_targets: int = -1
@export var attack_lifetime: float = 0.2

# @export var target_groups: Array[StringName] = []
# @export var damage: float = 10.0

var attacker_stats: Stats
var cooldown_timer: Timer
var locked := false

# var targets_hit_count: int = 0


func _ready() -> void:
    _setup_timer()


func _setup_timer() -> void:
    cooldown_timer = Timer.new()
    cooldown_timer.wait_time = attack_cooldown
    cooldown_timer.one_shot = true
    cooldown_timer.timeout.connect(func(): locked = false)
    add_child(cooldown_timer)


## Called by Player to inject stats
func initialize(stats: Stats) -> void:
    attacker_stats = stats


func can_attack() -> bool:
    return not locked


func start_attack(target_position: Vector2) -> void:
    if locked:
        return

    if attacker_stats == null:
        push_error("AttackModule: attacker_stats is not set")
        return

    locked = true

    var info = AttackInfo.new()
    info.damage = attacker_stats.current_damage
    info.max_targets = max_targets
    info.attack_lifetime = attack_lifetime

    info.target_factions = []
    match attacker_stats.faction:
        Stats.Faction.PLAYER:
            info.target_factions = [Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]
        Stats.Faction.ENEMY:
            info.target_factions = [Stats.Faction.PLAYER]
        Stats.Faction.NEUTRAL:
            info.target_factions = []  # or pick something if neutral attackers exist
        _:
            info.target_factions = []

    info.source_position = global_position
    # info.hit_sfx_key = &"hit"

    _execute_attack_logic(target_position, info)


func end_attack() -> void:
    if cooldown_timer.is_stopped():
        cooldown_timer.start()


## Virtual methods
func _execute_attack_logic(_pos: Vector2, _info: AttackInfo) -> void:
    pass
