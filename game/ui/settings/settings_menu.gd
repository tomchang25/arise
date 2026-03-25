class_name SettingsMenu
extends Control
## Settings overlay: pauses the game when open, unpauses on close.
## Provides Fullscreen toggle, Master/Music/SFX volume sliders,
## Apply / Cancel / Reset to Defaults buttons, and an Exit button.

signal closed

@export_group("Nodes")
@export var fullscreen_toggle: CheckButton
@export var master_slider: HSlider
@export var music_slider: HSlider
@export var sfx_slider: HSlider

# Values captured at open() time, restored by Cancel.
var _saved_fullscreen: bool
var _saved_master_db: float
var _saved_music_db: float
var _saved_sfx_db: float


func _ready() -> void:
    process_mode = PROCESS_MODE_ALWAYS
    hide()


func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed(&"ui_cancel"):
        _on_cancel_pressed()
        get_viewport().set_input_as_handled()

# -------------------------
# Public API
# -------------------------


func open() -> void:
    _save_settings()
    _sync_ui()
    show()
    get_tree().paused = true

# -------------------------
# Button Handlers
# -------------------------


func _on_apply_pressed() -> void:
    _apply_from_ui()
    _save_settings()


func _on_cancel_pressed() -> void:
    _restore_saved()
    _close()


func _on_reset_pressed() -> void:
    if fullscreen_toggle:
        fullscreen_toggle.button_pressed = false
    if master_slider:
        master_slider.value = 1.0
    if music_slider:
        music_slider.value = 1.0
    if sfx_slider:
        sfx_slider.value = 1.0


func _on_exit_pressed() -> void:
    get_tree().quit()

# -------------------------
# Internals
# -------------------------


func _close() -> void:
    hide()
    get_tree().paused = false
    closed.emit()


func _save_settings() -> void:
    _saved_fullscreen = get_window().mode == Window.MODE_FULLSCREEN
    _saved_master_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master"))
    _saved_music_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Music"))
    _saved_sfx_db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"SFX"))


func _sync_ui() -> void:
    if fullscreen_toggle:
        fullscreen_toggle.button_pressed = _saved_fullscreen
    if master_slider:
        master_slider.value = clampf(db_to_linear(_saved_master_db), 0.0, 1.0)
    if music_slider:
        music_slider.value = clampf(db_to_linear(_saved_music_db), 0.0, 1.0)
    if sfx_slider:
        sfx_slider.value = clampf(db_to_linear(_saved_sfx_db), 0.0, 1.0)


func _apply_from_ui() -> void:
    var window := get_window()
    if fullscreen_toggle:
        window.mode = Window.MODE_FULLSCREEN if fullscreen_toggle.button_pressed else Window.MODE_WINDOWED
    if master_slider:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), linear_to_db(master_slider.value))
    if music_slider:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), linear_to_db(music_slider.value))
    if sfx_slider:
        AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), linear_to_db(sfx_slider.value))


func _restore_saved() -> void:
    var window := get_window()
    window.mode = Window.MODE_FULLSCREEN if _saved_fullscreen else Window.MODE_WINDOWED
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Master"), _saved_master_db)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Music"), _saved_music_db)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"SFX"), _saved_sfx_db)
