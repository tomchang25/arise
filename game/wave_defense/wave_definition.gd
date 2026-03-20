## WaveDefinition
## Optional per-wave override resource.
## If group_table is set, it overrides the base config's table for that wave.
## If groups_override > 0, it overrides the computed group count for that wave.
class_name WaveDefinition
extends Resource

## Override the enemy group table for this wave.
## Leave null to use the base encounter config's table.
@export var group_table: EncounterGroupTable = null

## Override the total groups to kill for this wave.
## Set to 0 or less to use the auto-computed value (base + wave * increment).
@export var groups_override: int = 0
