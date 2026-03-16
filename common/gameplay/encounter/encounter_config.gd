class_name EncounterConfig
extends Resource

@export_group("Group Table")
@export var group_table: EncounterGroupTable

@export_group("Round Budget")
## How many groups to spawn before the round ends. -1 = endless round.
@export var groups_per_round: int = 10
## If true, spawning continues past the budget so enemies are always available to kill.
## Use for extermination-style rounds where the player must reach a kill count.
## If false, spawning stops once (killed + active) reaches the budget — player must
## clear remaining stragglers themselves.
## Use for wave-dense rounds where the group count is intentionally finite.
@export var spawn_beyond_budget: bool = false

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
