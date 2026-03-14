class_name EnemyData
extends Resource

@export_group("Stats")
@export var stats: Stats

@export_group("Perception")
@export var aggro_range: float = 200.0
@export var deaggro_range: float = 300.0

@export_group("Loot")
@export var drop_profile: LootDropProfile
