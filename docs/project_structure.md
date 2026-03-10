# Arise Project Structure

This document defines the main folder structure used in the Arise project.

## Top Level

- `common/`
  Shared reusable systems, modules, resources, and helpers.

- `game/`
  Game-specific content such as actors, items, missions, and UI.

- `global/`
  Autoloads, global scripts, and project-wide shared resources.

- `stage/`
  Playable stages, level content, testbeds, and stage-related scenes.

## Folder Rules

### `common/`
Use for reusable logic that is not tied to one specific actor or stage.

Examples:
- movement modules
- animation modules
- combat systems
- shared resources
- framework code

### `game/`
Use for actual game content.

Examples:
- player
- enemies
- summons
- items
- dungeon content
- missions
- game UI

### `global/`
Use for project-wide singletons and shared global systems.

Examples:
- event bus
- global script
- audio manager
- theme

### `stage/`
Use for stage and testing content.

Examples:
- levels
- runs
- testbeds
- tilesets

## General Rules

- Put reusable systems in `common/`
- Put game-specific content in `game/`
- Put autoloads and global-only systems in `global/`
- Put stage/playtest content in `stage/`
- Do not place gameplay scripts directly in the project root unless they are truly project-level files

## Guideline

When deciding where something belongs, use this rule:

- reusable across many places → `common/`
- belongs to the actual game content → `game/`
- global singleton / autoload → `global/`
- level or testing content → `stage/`
