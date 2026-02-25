class_name EnemyEncounterProfile
extends Resource

@export_group("Group Size")
@export var min_size: int = 5
@export var max_size: int = 10

@export_group("Spawn Scatter")
@export var spawn_radius: float = 60.0

@export_group("Units (weighted)")
@export var unit_entries: Array[WeightedSceneEntry] = []
