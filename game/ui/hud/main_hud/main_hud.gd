class_name MainHUD
extends Control
## Full-game HUD that composes player_hud, debug_hud, wave_hud, and summon_hud.
##
## Call bind_player(), bind_wave(), and bind_summon() after the scene is ready
## to wire each sub-HUD to its respective manager.

@export var player_hud: PlayerHUD
@export var debug_hud: DebugHUD
@export var wave_hud: WaveHUD
@export var summon_hud: SummonHUD
@export var minimap_hud: MinimapHUD
@export var settings_button: Button
@export var settings_menu: SettingsMenu


func _ready() -> void:
    if settings_button and settings_menu:
        settings_button.pressed.connect(settings_menu.open)


## Binds both player_hud and debug_hud to the given Stats object.
func bind_player(target_stats: Stats) -> void:
    if player_hud:
        player_hud.bind(target_stats)
    if debug_hud:
        debug_hud.bind(target_stats)


func bind_wave(controller: WaveDefenseController) -> void:
    if wave_hud:
        wave_hud.bind(controller)


func bind_summon(manager: SummonManager) -> void:
    if summon_hud:
        summon_hud.bind(manager)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(&"ui_cancel"):
        settings_menu.open()
        get_viewport().set_input_as_handled()
