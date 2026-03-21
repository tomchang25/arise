## Base class for all Player states.
## Mirrors EnemyState — gives every state a typed `player` handle
## and re-exports PlayerStateId so states don't need extra imports.
class_name PlayerState
extends State

## State ID enum shared by all player states.
## Kept here (not in Player) so states can reference it without a circular dep.
enum PlayerStateId {
    NULL = -1,
    IDLE = 0,
    MOVE = 1,
    ROLL = 2,
    ATTACK = 3,
}

var player: Player


func _ready() -> void:
    await owner.ready
    player = owner as Player
