class_name TesterAttacker
extends Node2D

const KEY_HEAL := KEY_H
const KEY_RESET := KEY_R

@export var combat: CombatModule
@export var dummy_container: Node

@export_group("Damage Presets")
@export var heal_amount := 500.0

@export var stats: Stats:
    set(value):
        stats = value
        stats.setup_stats()

        if is_inside_tree():
            combat.stats = stats


func _ready() -> void:
    if not combat:
        combat = find_child("CombatModule", true, false) as CombatModule

    stats.setup_stats()
    combat.stats = stats


func _process(_delta: float) -> void:
    var mouse_pos := get_global_mouse_position()

    if Input.is_action_pressed("mouse_left"):
        combat.perform_attack(Stats.AttackSlot.PRIMARY, mouse_pos)

    if Input.is_action_pressed("mouse_right"):
        combat.perform_attack(Stats.AttackSlot.SECONDARY, mouse_pos)

    if Input.is_key_pressed(KEY_HEAL):
        _heal_all()

    if Input.is_key_pressed(KEY_RESET):
        _reset_all()


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
