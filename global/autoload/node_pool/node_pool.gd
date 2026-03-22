extends Node

var _pools: Dictionary = { }


func prewarm(scene: PackedScene, count: int, parent: Node) -> void:
    for i in count:
        var node := acquire(scene, parent)
        release(node, scene)


func acquire(scene: PackedScene, parent: Node) -> Node:
    var key := scene.resource_path
    if _pools.has(key) and not _pools[key].is_empty():
        var p: Node = _pools[key].pop_back()
        parent.add_child(p)
        if p.has_method("reset"):
            p.reset()
        return p

    var node := scene.instantiate()
    parent.add_child(node)
    if node.has_method("reset"):
        node.reset()
    return node


func release(node: Node, scene: PackedScene) -> void:
    if node.get_parent() != null:
        node.get_parent().remove_child(node)

    var key := scene.resource_path
    if not _pools.has(key):
        _pools[key] = []
    _pools[key].append(node)

    if node.has_method("on_pooled"):
        node.on_pooled()
