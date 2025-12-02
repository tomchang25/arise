class_name ArmyState
extends State

enum ArmyStateId { NULL = -1, FOLLOW = 0, CHASE = 1, RETREAT = 2, ATTACK = 3 }

@onready var target: CharacterBody2D = self.owner
