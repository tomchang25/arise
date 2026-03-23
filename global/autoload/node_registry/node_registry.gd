extends Node

# Unified node lifecycle manager.
# Handles both pooled and non-pooled instantiation through a single acquire/release API.
#
# Pooled nodes are cached by scene resource_path and reused on acquire.
# Non-pooled nodes are instantiated fresh each time and never cached.
#
# Node lifecycle hooks (optional, implement on the node):
#   reset()      — called on acquire, use to restore default state
#   on_pooled()  — called on release, use to clean up before returning to registry

# -------------------------
# Internal
# -------------------------

# Pooled node cache: resource_path -> Array[Node]
var _registry: Dictionary = { }

# Tracks which scene path each active node was acquired from.
# Allows release(node) without needing to pass the scene again.
var _node_to_key: Dictionary = { }

# -------------------------
# Public API
# -------------------------


## Pre-instantiates [count] nodes into the registry for the given scene.
## Call during loading screens to avoid runtime instantiation spikes.
func prewarm(scene: PackedScene, count: int, parent: Node) -> void:
    for i in count:
        var node := acquire(scene, parent)
        release(node)


## Acquires a node for the given scene and adds it to [parent].
## If [pooled] is true, attempts to reuse a cached instance first.
## If no cached instance exists, or [pooled] is false, instantiates a fresh node.
func acquire(scene: PackedScene, parent: Node, pooled: bool = false) -> Node:
    var key := scene.resource_path

    if pooled and _registry.has(key) and not _registry[key].is_empty():
        var p: Node = _registry[key].pop_back()
        _node_to_key[p] = key
        parent.add_child(p)
        if p.has_method("reset"):
            p.reset()
        return p

    var node := scene.instantiate()
    # Track the key so release() does not require the scene to be passed again.
    _node_to_key[node] = key
    parent.add_child(node)
    if node.has_method("reset"):
        node.reset()
    else:
        push_warning("NodeRegistry.acquire: scene '%s' has no reset() method" % key)

    return node


## Returns a node to the registry and removes it from its parent.
## Only pooled nodes are cached; non-pooled nodes are freed instead.
## Does not require the original scene — the registry tracks it internally.
func release(node: Node) -> void:
    if not _node_to_key.has(node):
        push_warning("NodeRegistry.release: node was not acquired through the registry — freeing instead")
        node.queue_free()
        return

    var key: String = _node_to_key[node]
    _node_to_key.erase(node)

    if node.get_parent() != null:
        node.get_parent().remove_child(node)

    if not _registry.has(key):
        _registry[key] = []

    _registry[key].append(node)

    if node.has_method("set_enabled"):
        node.set_enabled(false)
    else:
        push_warning("NodeRegistry.release: scene '%s' has no set_enabled() method" % key)
