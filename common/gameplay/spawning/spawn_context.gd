class_name SpawnContext
extends Resource

@export var rng_seed: int = 0
@export var metadata: Dictionary = {}

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
