class_name TesterAttacker
extends Node2D

const BTN_LIGHT := MOUSE_BUTTON_LEFT
const BTN_HEAVY := MOUSE_BUTTON_RIGHT

const KEY_HEAL := KEY_H
const KEY_RESET := KEY_R

@export var attack: MeleeAttackModule
@export var dummy_container: Node

@export_group("Damage Presets")
@export var light_damage := 100.0
@export var heavy_damage := 300.0
@export var heal_amount := 500.0

var stats: Stats


func _ready() -> void:
    if not attack:
        attack = find_child("MeleeAttackModule", true, false) as MeleeAttackModule

    # test stats
    stats = Stats.new()
    stats.faction = Stats.Faction.PLAYER
    stats.base_damage = light_damage
    stats.setup_stats()

    attack.initialize(stats)
    attack.max_distance = 99999


func _process(_delta: float) -> void:
    var mouse_pos := get_global_mouse_position()

    if Input.is_action_pressed("mouse_right"):
        _do_attack(heavy_damage, mouse_pos)

    if Input.is_action_pressed("mouse_left"):
        _do_attack(light_damage, mouse_pos)

    if Input.is_key_pressed(KEY_HEAL):
        _heal_all()
    
    if Input.is_key_pressed(KEY_RESET):
        _reset_all()


func _do_attack(damage: float, target_pos: Vector2) -> void:
    if attack.can_attack():
        stats.base_damage = damage
        stats.recalculate_stats()

        attack.start_attack(target_pos)
        attack.end_attack()


func _heal_all():
    if not dummy_container:
        return
    for d in dummy_container.get_children():
        if d.has_method("heal"):
            d.heal(heal_amount)


func _reset_all():
    if not dummy_container:
        return
    for d in dummy_container.get_children():
        if d.has_method("reset_dummy"):
            d.reset_dummy()
