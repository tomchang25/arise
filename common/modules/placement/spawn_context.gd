class_name SpawnContext
extends Resource

@export var rng_seed: int = 0

@export var room_id: int = -1
@export var difficulty: int = 0

var rng: RandomNumberGenerator
var spawn_root: Node


func setup(_spawn_root: Node, _rng_seed: int = 0) -> void:
    spawn_root = _spawn_root
    rng_seed = _rng_seed


func ensure_rng() -> RandomNumberGenerator:
    if rng == null:
        rng = RandomNumberGenerator.new()
        if rng_seed != 0:
            rng.seed = rng_seed
        else:
            rng.randomize()
    return rng
