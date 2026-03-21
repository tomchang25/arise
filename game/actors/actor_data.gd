## Shared data resource base for all actor types (Army, Enemy).
## Subclasses (ArmyData, EnemyData) extend this with type-specific fields.
class_name ActorData
extends Resource

@export_group("Stats")
@export var stats: Stats

@export_group("Weapons")
## Weapons equipped on this actor. Loaded into CombatModule at runtime.
## Index 0 is the default weapon used by the attack state.
@export var weapons: Array[WeaponData] = []

@export_group("Behavior")
## When true, the actor may enter a WANDER state while idle near its anchor.
@export var has_wander: bool = false

## When true, the actor uses a deaggro detection zone to exit chase/attack states.
## Set to false for actors that disengage purely by distance threshold (e.g. army units).
@export var has_deaggro: bool = false

## Maximum distance from anchor_position before the actor forcibly returns home.
## A value of 0 disables leashing entirely.
@export var leash_distance: float = 0.0
