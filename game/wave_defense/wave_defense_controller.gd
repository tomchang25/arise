## WaveDefenseController
## Sits on top of EncounterController and manages escalating waves.
##
## Wave group budget: base_groups_per_wave + (wave_number - 1) * groups_increment_per_wave
## Example with defaults: Wave 1 = 10, Wave 2 = 20, Wave 3 = 30, ...
##
## Per-wave overrides: populate wave_definitions with WaveDefinition resources.
## Index 0 applies to Wave 1, index 1 to Wave 2, etc.
## If an index is out of range, the base config and formula are used.
class_name WaveDefenseController
extends Node

# -------------------------
# Signals
# -------------------------

## Emitted when a new wave begins.
signal wave_started(wave_number: int, total_groups: int)

## Emitted each time a group is killed during a wave.
signal wave_progress_changed(groups_killed: int, total_groups: int)

## Emitted when all groups in the current wave have been cleared.
signal wave_completed(wave_number: int)

# -------------------------
# Exports
# -------------------------

@export_group("Dependencies")
@export var encounter_controller: EncounterController

## Base encounter config used as a template (group_table, pacing settings).
## groups_per_round is overridden by wave logic.
@export var base_encounter_config: EncounterConfig

@export_group("Wave Scaling")
## Groups required to clear Wave 1.
@export var base_groups_per_wave: int = 10
## Additional groups added for each subsequent wave.
@export var groups_increment_per_wave: int = 10

@export_group("Per-Wave Overrides")
## Optional WaveDefinition resources for specific waves.
## Index 0 = Wave 1, index 1 = Wave 2, etc.
## Missing indices fall back to base config and the scaling formula.
@export var wave_definitions: Array[WaveDefinition] = []

# -------------------------
# Internal State
# -------------------------

var _current_wave: int = 0
var _total_groups_this_wave: int = 0
var _groups_killed_this_wave: int = 0
var _running: bool = false

# -------------------------
# Lifecycle
# -------------------------


func _ready() -> void:
    if encounter_controller != null:
        encounter_controller.round_cleared.connect(_on_round_cleared)
        encounter_controller.group_depleted.connect(_on_group_depleted)

# -------------------------
# Public API
# -------------------------


## Start the wave defense sequence from wave 1.
func start() -> void:
    _current_wave = 1
    _running = true
    _launch_wave()


## Stop the wave defense and end the underlying encounter.
func stop() -> void:
    _running = false
    if encounter_controller != null:
        encounter_controller.end()


func get_current_wave() -> int:
    return _current_wave


func get_total_groups_this_wave() -> int:
    return _total_groups_this_wave


func get_groups_killed_this_wave() -> int:
    return _groups_killed_this_wave


func get_groups_remaining_this_wave() -> int:
    return maxi(0, _total_groups_this_wave - _groups_killed_this_wave)

# -------------------------
# Internal
# -------------------------


func _launch_wave() -> void:
    if encounter_controller == null or base_encounter_config == null:
        push_warning("WaveDefenseController: missing encounter_controller or base_encounter_config")
        return

    _groups_killed_this_wave = 0
    _total_groups_this_wave = _compute_groups_for_wave(_current_wave)

    var config := _build_config_for_wave(_current_wave)
    encounter_controller.start(config)

    wave_started.emit(_current_wave, _total_groups_this_wave)


func _compute_groups_for_wave(wave: int) -> int:
    var definition := _get_definition(wave)
    if definition != null and definition.groups_override > 0:
        return definition.groups_override
    return base_groups_per_wave + (wave - 1) * groups_increment_per_wave


func _build_config_for_wave(wave: int) -> EncounterConfig:
    # Duplicate so we don't mutate the original exported resource.
    var config := base_encounter_config.duplicate() as EncounterConfig
    config.groups_per_round = _total_groups_this_wave
    config.spawn_mode = EncounterController.SpawnMode.WAVE

    var definition := _get_definition(wave)
    if definition != null and definition.group_table != null:
        config.group_table = definition.group_table

    return config


func _get_definition(wave: int) -> WaveDefinition:
    var idx := wave - 1
    if idx >= 0 and idx < wave_definitions.size():
        return wave_definitions[idx]
    return null


func _on_group_depleted(_group: EnemyGroup) -> void:
    _groups_killed_this_wave += 1
    wave_progress_changed.emit(_groups_killed_this_wave, _total_groups_this_wave)


func _on_round_cleared() -> void:
    wave_completed.emit(_current_wave)
    _current_wave += 1
    if _running:
        _launch_wave()
