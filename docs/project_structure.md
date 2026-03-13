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
* framework utilities
* shared gameplay resources
* generic helpers
* rendering utilities such as shaders or VFX

Examples:

* movement modules
* animation modules
* combat systems
* shared gameplay resources
* framework utilities

Reusable gameplay modules and gameplay-related systems are typically placed under:

```
common/gameplay/
```

These components can be reused by multiple actors such as players, enemies, summons, or world objects.

Subfolders under `common/` are typically organized by responsibility:

```
common/framework   → engine-style infrastructure (state machines, core helpers)
common/gameplay    → reusable gameplay modules and systems
common/utils       → generic helper utilities
common/rendering   → shaders, VFX, and rendering utilities
```

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

game/
└ actors/
└ items/

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

stage/
├ runs/
└ testbeds/

Runs represent playable game flows or missions, while testbeds are used for isolated feature testing.

---

# Placement Rules

Place files based on their responsibility:

* **Reusable systems or shared logic** → `common/`
* **Playable game content (actors, items, UI, missions)** → `game/`
* **Global singletons or autoload systems** → `global/`
* **Levels, runs, or testing scenes** → `stage/`

Avoid placing gameplay scripts directly in the project root unless they are truly project-level files.
