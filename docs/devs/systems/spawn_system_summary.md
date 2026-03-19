# Spawn System

Location  
`common/gameplay/spawning/`

Purpose  
Handles runtime entity spawning for reusable gameplay content in Arise.  
The system supports direct scene spawning, weighted table selection, optional warning telegraphs before spawn, and helper utilities for picking valid spawn positions.  
It separates spawn configuration (`SpawnAction`, weighted resources) from runtime execution (`SpawnRequest`, executors, points, context, result).

Core Components

`SpawnAction`  
Base resource that defines how a spawn is executed and how the final parent is resolved.

`SpawnPackedSceneAction`  
Spawns a single `PackedScene` with configurable parent selection, offset, scatter, and rotation rules.

`SpawnFromWeightedTableAction`  
Picks a scene from `WeightedSceneTable`, then forwards execution through `SpawnPackedSceneAction` behavior.

`SpawnRequest`  
Main runtime request object. Stores spawn inputs, resolves `SpawnContext`, executes direct or warning spawn flow, and returns `SpawnResult`.

`SpawnExecutor`  
Executes a spawn immediately at a node or world position. Creates a temporary anchor when spawning from a raw position.

`SpawnWarningExecutor`  
Executes delayed spawn flow through `WarningSpawnPoint` so telegraph VFX/signs can play before the real spawn.

`SpawnPoint`  
Scene anchor node that executes a configured action and emits `placed(node)` when a node is spawned.

`WarningSpawnPoint`  
Specialized `SpawnPoint` that shows a warning sign / VFX, waits for `warning_time`, then executes and frees itself.

`SpawnContext`  
Shared runtime data passed through the system, including spawn parent, source node, RNG seed, metadata, and lazy RNG creation.

`SpawnResult`  
Structured spawn output describing success, spawned node, requested/final position, warning usage, failure reason, and metadata.

`SpawnPositionFinder`  
Utility for searching a valid point inside a radius or annulus using a validator.

`SpawnPositionValidator`  
Position validation helper for bounds, exclusion zones, screen exclusion, and physics overlap checks.

`SpawnRegistry`  
Weak-reference runtime tracker for spawned nodes. Useful for cleanup, deduplication, and bulk despawn.

`WeightedSceneTable` / `WeightedSceneEntry`  
Reusable weighted scene selection resources.

`EnemyEncounterProfile`, `WeightedEncounterTable`, `WeightedEncounterEntry`  
Higher-level encounter resources for group-based enemy spawn selection.

System Flow

### Direct spawn

`Spawn source`  
→ `SpawnRequest.setup_direct()`  
→ `_resolve_context()`  
→ `SpawnExecutor.execute_at_position()` or `execute_at_node()`  
→ temporary / real anchor  
→ `SpawnAction.execute()`  
→ spawned node  
→ `SpawnResult`

### Warning spawn

`Spawn source`  
→ `SpawnRequest.setup_warning()`  
→ `_resolve_context()`  
→ `SpawnWarningExecutor.execute_at_position()`  
→ `WarningSpawnPoint.start()`  
→ `_play_warning()`  
→ `SpawnPoint.execute()`  
→ spawned node  
→ `SpawnResult`

### Placement helper flow

`center + radius rules`  
→ `SpawnPositionFinder`  
→ `SpawnPositionValidator.is_valid()`  
→ valid world position  
→ `SpawnRequest`

Main API

`SpawnRequest.setup_direct(action, global_position, spawn_parent, source_node, rng_seed, metadata, ctx) -> SpawnRequest`  
Prepare an immediate spawn request.

`SpawnRequest.setup_warning(action, global_position, spawn_parent, source_node, rng_seed, metadata, ctx) -> SpawnRequest`  
Prepare a warning / telegraphed spawn request.

`SpawnRequest.execute() -> SpawnResult`  
Execute the request and return structured spawn output.

`SpawnExecutor.execute_at_node(action, anchor, ctx) -> Node`  
Execute a spawn action using an existing anchor node.

`SpawnExecutor.execute_at_position(action, global_position, spawn_parent, ctx) -> Node`  
Execute a spawn action from a raw world position using a temporary anchor.

`SpawnWarningExecutor.execute_at_position(warning_point_scene, action, global_position, spawn_parent, ctx) -> Node`  
Play warning flow, then perform the actual spawn.

`SpawnPoint.setup(action, ctx)`  
Assign runtime spawn data to a point.

`SpawnPoint.start() -> Node`  
Start execution on the point.

`SpawnPositionFinder.find_position_in_radius(center, radius, validator, rng, max_attempts) -> Variant`  
Try to find a valid spawn point inside a circle.

`SpawnPositionFinder.find_position_in_annulus(center, min_radius, max_radius, validator, rng, max_attempts) -> Variant`  
Try to find a valid spawn point inside an annulus.

`SpawnPositionValidator.is_valid(global_position) -> bool`  
Check whether a position satisfies spatial and collision rules.

`WeightedSceneTable.pick_scene(rng) -> PackedScene`  
Pick a scene from weighted entries.

`WeightedEncounterTable.pick_encounter(rng) -> EnemyEncounterProfile`  
Pick an encounter profile from weighted entries.

Typical Usage

### Manual direct spawn

```gdscript
var request := SpawnRequest.new()
request.setup_direct(spawn_action, spawn_position, world, self, rng_seed, {
    "player": player,
    "controller": self,
})

var result := await request.execute()
if result.success:
    var spawned := result.spawned_node
```

### Manual warning spawn

```gdscript
var request := SpawnRequest.new()
request.setup_warning(spawn_action, spawn_position, world, self, rng_seed)

var result := await request.execute()
```

### Weighted spawn action

```gdscript
var action := SpawnFromWeightedTableAction.new()
action.table = spawn_table

var result := await SpawnRequest.new() \
    .setup_direct(action, spawn_position, world) \
    .execute()
```

### Position search before spawn

```gdscript
var validator := SpawnPositionValidator.new()
validator.world_2d = get_world_2d()
validator.use_excluded_radius = true
validator.excluded_center = player.global_position
validator.excluded_radius = 120.0

var position = SpawnPositionFinder.find_position_in_annulus(
    player.global_position,
    120.0,
    240.0,
    validator
)

if position != null:
    await SpawnRequest.new().setup_direct(spawn_action, position, world).execute()
```

Design Rules

- The spawn system coordinates resources, points, runtime context, and execution helpers, so it should be documented as a **system**, not a module.  
- Spawn behavior is resource-driven: `SpawnAction` subclasses define *how* something is spawned, while callers decide *when* and *why* to spawn.  
- Runtime state is passed explicitly through `SpawnContext`; dependencies are not auto-discovered.  
- Parent resolution is centralized in `SpawnAction.resolve_parent()` to keep spawn rules consistent across actions.  
- Position search and position validation stay separate from actual spawn execution.  
- Warning spawn is intentionally asynchronous; direct spawn is immediate.  
- `SpawnResult` should be preferred over raw node returns at request level because it preserves failure reason and final position.  
- `SpawnRegistry` is optional runtime support, not a required part of basic spawn execution.

Notes

- `SpawnRequest.execute()` returns `SpawnResult`, so callers should check `result.success` or `result.has_node()` instead of assuming a node always exists.  
- `SpawnPackedSceneAction` only applies transform logic when the spawned instance is `Node2D`.  
- `SpawnContext.get_rng()` is lazy and deterministic when `rng_seed != 0`.  
- `SpawnFromWeightedTableAction` currently reuses `SpawnPackedSceneAction` at runtime instead of duplicating spawn logic.  
- `SpawnExecutor.execute_at_position()` creates a temporary `Node2D` anchor, which keeps world-position-based spawns compatible with action code that expects an anchor.  
- `WarningSpawnPoint` defaults to `free_after_execute = true`, so telegraph points clean themselves up after spawning.  
- `SpawnPositionFinder` returns `Variant` because it may return `null` when no valid position is found.  
- Encounter resources exist for higher-level enemy group spawning, but they are configuration resources rather than execution entry points by themselves.
