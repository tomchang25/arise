class_name EnemyData
extends Resource

@export_group("Stats")
@export var stats: Stats

@export_group("Weapons")
## Weapons equipped on this enemy. Loaded into CombatModule at runtime.
## Index 0 is the default weapon used by the attack state.
## Add more entries for enemies with multiple simultaneous attack types.
@export var weapons: Array[WeaponData] = []

@export_group("Perception")
@export var aggro_range: float = 200.0
@export var deaggro_range: float = 300.0

@export_group("Loot")
@export var drop_profile: LootDropProfile
