class_name SpawnPoint
extends Node2D

signal placed(node: Node)

@export_group("Spawn")
@export var spawn_parent: Node

@export_group("Runtime")
@export var free_after_execute: bool = false

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

    if free_after_execute:
        queue_free()

    return placed_node
