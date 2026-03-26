class_name EncounterConfig
extends Resource

@export_group("Group Table")
@export var group_table: EncounterGroupTable

@export_group("Round Budget")
## How many groups to spawn before the round ends. -1 = endless round.
@export var groups_per_round: int = 10
## Controls how the kill budget interacts with spawning and the round-cleared signal.
##
##   WAVE          — Never spawns more groups than the budget allows.
##                   round_cleared emits only after all spawned groups are killed
##                   and the field is empty.
##
##   EXTERMINATION — Spawns beyond the budget so there are always enemies on the
##                   field.  round_cleared emits as soon as kills reach the budget,
##                   regardless of how many groups remain alive.  Spawning stops
##                   once the budget is reached.
##
##   ENDLESS       — Same signal behaviour as EXTERMINATION (emits on budget hit),
##                   but spawning never stops afterwards.  Set groups_per_round = -1
##                   to suppress the signal entirely for a truly infinite encounter.
@export var spawn_mode: EncounterController.SpawnMode = EncounterController.SpawnMode.WAVE

@export_group("Pacing")
## How many groups should be alive at the same time before spawning pauses.
@export var target_active_groups: int = 3
## Max groups spawned in a single pacing tick.
@export var max_spawn_per_tick: int = 2
## Seconds between each pacing tick.
@export var spawn_interval: float = 1.5
## Delay before the very first spawn after start() or start_next_round().
@export var initial_spawn_cooldown: float = 3.0


func is_valid() -> bool:
    return group_table != null and group_table.is_valid()
