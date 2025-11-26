class_name PlayerState
extends State

enum PlayerStateId { NULL = -1, IDLE = 0, WALK = 1, RUN = 2, ROLL = 3, ATTACK = 4 }

@onready var player: Player = self.owner
