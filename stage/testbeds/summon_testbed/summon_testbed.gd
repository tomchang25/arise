## Summon System Testbed
## Tests the full summon pipeline: summoning ninja_green units, pathfinding,
## combat against dummy targets, and SummonHUD + PlayerHUD integration.
##
## Keybinds
## --------
##   [1–4] — Summon unit type (handled by SummonManager)
##   [R]   — Reset all dummy targets to their spawn positions
extends Node2D

const ACTION_RESET_DUMMIES := "summon_test_reset_dummies"

@export_group("Scene References")
@export var player: Node2D
@export var summon_manager: SummonManager
@export var dummies_root: Node2D
@export var player_hud: PlayerHUD
@export var summon_hud: SummonHUD

@export_group("Debug")
@export var debug_label: Label


func _ready() -> void:
    _ensure_actions()
    _bind_hud()
    _update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_RESET_DUMMIES):
        _reset_dummies()
        get_viewport().set_input_as_handled()

# -------------------------
# HUD Binding
# -------------------------


func _bind_hud() -> void:
    var player_stats: Stats = null
    if player is Player:
        player_stats = (player as Player).stats
    if player_hud and player_stats:
        player_hud.bind(player_stats)

    if summon_hud and summon_manager:
        summon_hud.bind(summon_manager)

# -------------------------
# Dummy Reset
# -------------------------


func _reset_dummies() -> void:
    if dummies_root == null:
        return
    for child in dummies_root.get_children():
        if is_instance_valid(child) and child.has_method("reset_dummy"):
            child.reset_dummy()

# -------------------------
# Debug Label
# -------------------------


func _update_debug_label() -> void:
    if debug_label == null:
        return
    debug_label.text = "\n".join(
        [
            "[1–4]  Select group",
            "[F1–F4]  Summon type",
            "[R]    Reset dummies",
        ],
    )

# -------------------------
# Input Setup
# -------------------------


func _ensure_actions() -> void:
    _ensure_key_action(ACTION_RESET_DUMMIES, KEY_R)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return
    InputMap.add_action(action_name)
    var input_event := InputEventKey.new()
    input_event.physical_keycode = keycode
    InputMap.action_add_event(action_name, input_event)
