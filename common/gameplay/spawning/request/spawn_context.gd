class_name SpawnContext
extends RefCounted

var rng_seed: int = 0
var metadata: Dictionary = {}

var spawn_parent: Node
var source_node: Node

var _rng: RandomNumberGenerator


func setup(parent: Node = null, setup_seed: int = 0, source: Node = null, extra_metadata: Dictionary = {}) -> void:
    spawn_parent = parent
    rng_seed = setup_seed
    source_node = source
    metadata = extra_metadata
    _rng = null


func get_rng() -> RandomNumberGenerator:
    if _rng == null:
        _rng = RandomNumberGenerator.new()
        if rng_seed != 0:
            _rng.seed = rng_seed
        else:
            _rng.randomize()

    return _rng


# Resolves a spawn parent from a group name, falling back to current_scene.
# Always uses is_instance_valid so freed Object(null) nodes are rejected.
static func resolve_spawn_parent(spawn_group: String, source: Node = null) -> Node:
    var tree: SceneTree

    if source != null and is_instance_valid(source):
        tree = source.get_tree()
    else:
        tree = Engine.get_main_loop() as SceneTree

    if tree == null:
        return null

    if not spawn_group.is_empty():
        var group_node := tree.get_first_node_in_group(spawn_group)

        if is_instance_valid(group_node):
            return group_node

        Debug.warn("SpawnContext: spawn_group '%s' not found, falling back to current_scene" % spawn_group)

    return tree.current_scene
