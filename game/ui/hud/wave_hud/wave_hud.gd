## WaveHUD
## Displays the current wave number and a progress bar showing groups cleared.
## Bind to a WaveDefenseController via bind() or the wave_defense_controller export.
class_name WaveHUD
extends Control

# -------------------------
# Exports
# -------------------------

@export var wave_defense_controller: WaveDefenseController

@export_group("Nodes")
@export var progress_bar: ProgressBar
@export var wave_label: Label

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if wave_defense_controller != null:
        bind(wave_defense_controller)
    else:
        _refresh(0, 0, 0)


# -------------------------
# Public API
# -------------------------


func bind(controller: WaveDefenseController) -> void:
    _unbind()
    wave_defense_controller = controller

    if wave_defense_controller == null:
        return

    wave_defense_controller.wave_started.connect(_on_wave_started)
    wave_defense_controller.wave_progress_changed.connect(_on_wave_progress_changed)
    wave_defense_controller.wave_completed.connect(_on_wave_completed)


# -------------------------
# Internal
# -------------------------


func _unbind() -> void:
    if wave_defense_controller == null:
        return
    if wave_defense_controller.wave_started.is_connected(_on_wave_started):
        wave_defense_controller.wave_started.disconnect(_on_wave_started)
    if wave_defense_controller.wave_progress_changed.is_connected(_on_wave_progress_changed):
        wave_defense_controller.wave_progress_changed.disconnect(_on_wave_progress_changed)
    if wave_defense_controller.wave_completed.is_connected(_on_wave_completed):
        wave_defense_controller.wave_completed.disconnect(_on_wave_completed)


func _refresh(wave: int, killed: int, total: int) -> void:
    if wave_label != null:
        wave_label.text = "Wave %d" % wave if wave > 0 else "Wave -"

    if progress_bar != null:
        progress_bar.max_value = maxi(1, total)
        progress_bar.value = killed


# -------------------------
# Signal Callbacks
# -------------------------


func _on_wave_started(wave_number: int, total_groups: int) -> void:
    _refresh(wave_number, 0, total_groups)


func _on_wave_progress_changed(groups_killed: int, total_groups: int) -> void:
    if progress_bar != null:
        progress_bar.max_value = maxi(1, total_groups)
        progress_bar.value = groups_killed


func _on_wave_completed(wave_number: int) -> void:
    # Show the bar as fully filled briefly before the next wave resets it.
    if progress_bar != null:
        progress_bar.value = progress_bar.max_value
    if wave_label != null:
        wave_label.text = "Wave %d" % wave_number
