# Arise Project Structure

This document defines the main folder structure used in the Arise project.

Its purpose is to define **where different types of content belong** in the project.

---

# Top Level

**common/**
Shared reusable systems, modules, resources, and helpers.

**game/**
Game-specific content such as actors, items, missions, and UI.

**global/**
Autoloads, global scripts, and project-wide shared resources.

**stage/**
Playable stages, level content, testbeds, and stage-related scenes.

---

# Folder Rules

## common/

Use this folder for **reusable logic that is not tied to a specific actor, level, or game instance**.

Typical contents include:

* reusable gameplay systems
* reusable gameplay modules
* reusable gameplay controllers
* framework utilities
* shared gameplay resources
* generic helpers
* rendering utilities such as shaders or VFX

Reusable gameplay modules, systems, and controllers are typically placed under:

```
common/gameplay/
```

These components can be reused by multiple actors such as players, enemies, summons, or world objects, and across different stage types.

Subfolders under `common/` are typically organized by responsibility:

```
common/framework   → engine-style infrastructure (state machines, core helpers)
common/gameplay    → reusable gameplay modules, systems, and controllers
common/utils       → generic helper utilities
common/rendering   → shaders, VFX, and rendering utilities
```

### common/gameplay/ structure

```
common/gameplay/
  spawning/     → spawn system (SpawnRequest, SpawnExecutor, SpawnAction, etc.)
  encounter/    → encounter controllers and profiles
  despawn/      → DespawnController
  loot/         → loot drop modules and resources
  combat/       → combat modules
  movement/     → movement and navigation modules
  ...
```

### The three kinds of content in common/gameplay/

**Module**
Attached to an actor, executes behavior on behalf of that actor.
Has no standalone existence — always lives on or near a specific node.
Examples: `HealthBarModule`, `DamageNumberModule`, `LootDropModule`, `NavigationModule`.

**System**
A collection of related resources, helpers, and runtime objects that work together to solve one problem.
Not a single node — it is a folder of cooperating pieces.
Examples: the `spawning/` folder is a system — `SpawnRequest`, `SpawnExecutor`, `SpawnContext`, `SpawnAction` subclasses all live there together.

**Controller**
A standalone runtime node that makes ongoing decisions by coordinating one or more systems.
Has its own lifecycle (starts, ticks, stops), holds state, and responds to events.
Examples: `EncounterController`, `OpenMapEncounterController`, `DespawnController`.

Use **Controller** when the node ticks every frame or responds to events to make active decisions.
Use **Module** when the node executes behavior on behalf of a specific actor.
Use a **System** (folder) when the concept requires multiple cooperating pieces with no single entry point.

---

## game/

Use this folder for **actual game content**.

This includes things that are part of the playable game rather than reusable systems.

Examples:

* player
* enemies
* summons
* items
* dungeon content
* missions
* game UI

Typical structure example:

```
game/
└ actors/
└ items/
```

Actors usually contain their own scenes, scripts, art assets, and data related to that actor.

---

## global/

Use this folder for **project-wide global systems**.

These are usually configured as **autoloads**.

Examples:

* event bus
* audio manager
* global state managers
* theme resources
* configuration managers

Only systems that must be globally accessible should be placed here.

---

## stage/

Use this folder for **stage, level, and testing content**.

Examples:

* playable levels
* run scenes
* stage scenes
* testbeds
* tilesets
* level prototypes

Typical layout:

```
stage/
├ runs/
└ testbeds/
```

Runs represent playable game flows or missions, while testbeds are used for isolated feature testing.

---

# Placement Rules

Place files based on their responsibility:

* **Reusable systems, modules, or controllers** → `common/`
* **Playable game content (actors, items, UI, missions)** → `game/`
* **Global singletons or autoload systems** → `global/`
* **Levels, runs, or testing scenes** → `stage/`

Avoid placing gameplay scripts directly in the project root unless they are truly project-level files.