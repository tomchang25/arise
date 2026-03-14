class_name EnemyState
extends State

enum EnemyStateId { NULL = -1, IDLE = 0, WANDER = 1, CHASE = 2, ATTACK = 3, BACK = 4, LEASH_BACK = 5 }

var enemy: Enemy


func _ready() -> void:
    await owner.ready
    enemy = owner as Enemy
