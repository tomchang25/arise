class_name EnemyGroupProfile
extends Resource


@export var group_scene: PackedScene = preload("res://entity/actor/npc/enemy/enemy_group/enemy_group.tscn")
@export var unit_table: WeightedSpawnTable
@export var min_size: int = 5
@export var max_size: int = 10
