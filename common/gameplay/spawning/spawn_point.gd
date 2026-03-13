class_name SpawnPoint
extends Node2D

signal placed(node: Node)

@export_group("Spawn")
@export var spawn_parent: Node

var _action: SpawnAction
var _ctx: SpawnContext


func setup(action: SpawnAction, ctx: SpawnContext) -> void:
    _action = action
    _ctx = ctx

    if _ctx != null and _ctx.spawn_parent == null and spawn_parent != null:
        _ctx.spawn_parent = spawn_parent


func start() -> Node:
    return execute()


func execute() -> Node:
    if _action == null:
        Debug.warn("SpawnPoint: action is null")
        return null

    var placed_node := _action.execute(self, _ctx)
    if placed_node != null:
        placed.emit(placed_node)

    return placed_node
