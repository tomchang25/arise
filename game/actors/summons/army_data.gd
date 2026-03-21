class_name ArmyData
extends Resource

@export_group("Stats")
@export var stats: Stats

@export_group("Weapons")
## Weapons equipped on this army unit. Loaded into CombatModule at runtime.
## Index 0 is the default weapon used by the attack state.
@export var weapons: Array[WeaponData] = []

@export_group("Perception")
@export var track_range: float = 100.0
@export var attack_range: float = 50.0
