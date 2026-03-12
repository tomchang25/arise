# **Scratchpad**

Stats update for pickup system

## File Naming and Folder Location

Try to keep the pattern stable:

- feature system script → `_module.gd`
- base data resource → `_data.gd`, `_event.gd`, `_profile.gd`, `_table.gd`
- scene companion → same base name as script where possible
- resource scripts → module or entity → data/
- .tres presets → data/presets/
-

## SFX Naming

| ID | 庫命名 | 音效名 | 用途 |
| --- | --- | --- | --- |
| swing_light | weapon_swing_light | whoosh | 普通攻擊 |
| swing_heavy | weapon_swing_heavy | heavy whoosh | 重攻擊 |
| hit_flesh | impact_flesh | thud | 命中敵人 |
| hit_metal | impact_metal | clang | 格擋 |
| enemy_die | enemy_death | death burst | 敵人死亡 |
| pickup_spawn | pickup_spawn | drop | 掉落資源 |
| pickup_collect | pickup_collect | pling | 吸收 |
| item_drop | item_drop | clink | 掉寶 |
| item_collect | item_collect | pop | 撿裝備 |
| ui_click | ui_click | tick | UI按鈕 |
| ui_confirm | ui_confirm | confirm | UI確認 |
| ui_cancel | ui_cancel | cancel | UI返回 |

# Demo Production Plan

### Week 1 - 3/12 -3/18

Gameplay loop.

```
Summon system
Enemy spawning
Basic dialog
Basic objective
Player simple refactor
Enemy simple refactor
Allies simple refactor
--- Finished
Basic debug
Audio refactor
Pickup system Finished
```

---

### Week 2 - 3/19 -3/25

Boss + polish.

```
Dragon boss
Dragon attacks
Dragon death
Unlock dragon summon
Chaos mode
```

---

### Week 3 - 3/25 -3/31

Polish.

```
Sound
Particles
Balance
Bug fixing
Build export
Itch page
```

# **Core Systems**

# Refactored Modules

## Movement Module

- [x]  Core Features
    - [x]  CharacterBody2D movement execution isolated inside module
    - [x]  Manual velocity input supported
    - [x]  Path velocity input supported
    - [x]  Manual / path mode switching supported
    - [x]  Stop / clear motion helpers implemented
- [x]  Advanced Movement
    - [x]  Acceleration / deceleration smoothing implemented
    - [x]  Knockback
        - [x]  Knockback velocity channel implemented
        - [x]  Knockback friction decay implemented
    - [ ]  Add explicit dash / roll compatibility rules if needed
        - [ ]  Temporary dash / roll movement override supported
        - [ ]  Dash-to-destination movement supported
        - [ ]  Switchable collision ignore during dash supported
            - [ ]  Ignore other actors
            - [ ]  Optionally ignore world collision
        - [ ]  Dash priority over manual / path / knockback flow defined
        - [ ]  Dash end restores normal movement state cleanly

## Pathfinding Module

- [x]  Core Features
    - [x]  NavigationAgent2D movement planning isolated inside module
    - [x]  Global target position supported
    - [x]  Follow target node supported
    - [x]  Path velocity output wired into MovementModule
    - [x]  Navigation finished signal implemented
    - [x]  Target changed signal implemented
    - [x]  Stop / clear path helpers implemented
- [x]  Path Update Flow
    - [x]  Target refresh interval supported
    - [x]  Continuous path recompute handled by module
    - [x]  Arrive distance configurable
    - [x]  Max speed configurable
    - [x]  Repath tolerance / anti-jitter guard implemented
- [x]  Avoidance / Safety
    - [x]  NavigationAgent avoidance optional
    - [x]  NavigationAgent avoidance optional
    - [x]  `velocity_computed` safe velocity supported
    - [x]  Module clears path velocity when disabled
    - [x]  Module clears path velocity when target is gone
    - [x]  Module handles missing dependencies safely
- [ ]  Debug / Polish
    - [x]  Debug draw for target / path state
    - [ ]  Optional stuck handling
        - Handle agents stuck near goal due to avoidance / crowd pressure
        - Accept near-goal arrival or retry path
- [x]  Testbed
    - [x]  Base Test Setup
        - [x]  Pathfinding test dummy
        - [x]  Pathfinding sandbox scene
        - [x]  Single dummy move / follow / stop flow
        - [x]  Group dummy move / follow / stop flow
    - [x]  Obstacle / Navigation Validation
        - [x]  Verify static obstacle blocks path through navigation data, not only physics collision
        - [x]  Verify avoidance is separated from obstacle pathing behavior
        - [x]  Add one simple bush / blocker validation scene if needed

## Animation Module

- [x]  Core Module
    - [x]  Dedicated `AnimationModule` exists
    - [x]  AnimationTree playback cache implemented
    - [x]  AnimationTree state travel helper implemented
    - [x]  Blend position update helper implemented
    - [x]  Time scale control helper implemented
    - [x]  Facing direction cache implemented
    - [x]  `animation_finished` signal bridge implemented
- [x]  Module Usability / Safety
    - [x]  Add explicit `enabled` switch
    - [x]  Add auto-wire for `actor` / `animation_tree` if possible
    - [x]  Add runtime reset when disabled
    - [x]  Add helper validation for missing playback / tree / paths
    - [x]  Standardize public API naming with other modules

## Loot Module

- [x]  Core Features
    - [x]  **Loot roll system implemented** — drop tables support weighted selection, chance rolls, and amount rolls.
    - [x]  **Drop results generated correctly** — roll results are converted into structured drop result data.
    - [x]  **Loot spawning pipeline works** — drops can be triggered from one function, spawned with scatter, and emit a `loot_dropped` signal.
- [x]  Supported pickup module
- [x]  Robustness
    - [x]  Validate bad drop entries
        - [x]  Missing pickup scene
        - [x]  Missing reward data
    - [x]  Validate empty / broken drop table
- [x]  Future Features
    - [x]  **Multiple independent drop tables per loot profile**
        - [x]  `LootDropProfile` contains several `LootDropTable`
        - [x]  Each `LootDropTable` rolls independently
        - [x]  Entry weights only compete within the same table
        - [x]  Support setups like:
            - [x]  `xA` rolls from common resource table
            - [x]  `xB` rolls from common item table
            - [x]  `xC` rolls from rare item table
    - [ ]  **Shared drop entries / reusable loot setup**
        - [ ]  Allow common drop entries to be reused across multiple loot tables
        - [ ]  Reduce repeated manual setup for common rewards such as gold, mana, and basic resources
        - [ ]  Add a simple workflow to create loot tables from shared entry definitions instead of rebuilding similar entries every time
    - [ ]  **Simple reward scaling**
        - [ ]  Keep the same base `LootDropProfile` for the same mob family
        - [ ]  Support enemy-side amount scaling for level, tier, or rank
        - [ ]  Allow elites / bosses to add an optional bonus rare table without replacing the full base profile
        - [ ]  Keep base loot tables focused on reward composition, while final quantity is adjusted at runtime
    - [ ]  Luck / rarity modifier (Buff)
    - [ ]  Cleanup debug system

    ## Simple technical summary

    - **Base profile** decides **what can drop**
    - **Tables** decide **how each category rolls**
    - **Entries** decide **base chance, weight, and amount**
    - **Enemy-side scaling** adjusts **final quantity** for stronger variants
    - **Elite / boss bonus table** adds special rewards without duplicating the whole profile

    This keeps the loot module simple:

    - profile = composition
    - table = independent roll bucket
    - entry = base reward row
    - enemy = runtime scaling input

## Item / Resources System

- [x]  Core Features
    - [x]  **Shared reward data exists** — item data and resource reward data define the reward identity
    - [x]  **Reward data is reusable** — the same gold / mana / soul / health data can be reused by many loot entries and pickups
    - [x]  **Reward types are separated clearly** — item rewards and resource rewards do not share the same runtime handling by accident
- [ ]  Runtime Flow
    - [ ]  **Items support progression / inventory-style rewards**
    - [x]  **Resources support direct value rewards**
        - [x]  Gold adds currency
        - [x]  Mana orb restores or grants mana-related value
        - [x]  Health orb restores health-related value
        - [x]  Soul orb adds soul-related value
    - [x]  **Reward data can be consumed by pickups and loot drops**
- [x]  Robustness
    - [x]  Validate missing reward data
- [ ]  Future Features
    - [ ]  Shared item/resource base if more common behavior appears

## Pickup Module

### Core Features

- [x]  **Pickup interaction works** — actors can trigger pickup when entering the pickup area
- [x]  **Pickup reward application works** — pickup applies reward data to the collector
- [x]  **Pickup removes itself after collection** — pickup is consumed once reward is applied
- [x]  **Pickup integrates with loot system** — loot drops spawn pickups correctly
- [x]  Pickup magnet / auto-collect radius
- [x]  Pickup lifetime / auto-despawn
- [x]  Prevent pickup if collector stats are already full
- [x]  Pickup sound hooks

### Robustness

- [x]  **Validate pickup configuration**
    - [x]  Missing reward data
    - [x]  Missing pickup scene setup
- [x]  Prevent duplicate pickup triggers
- [x]  Prevent invalid collector from applying reward
- [x]  Prevent broken pickup from silently failing
- [x]  Pickup should check **hurtbox → body order** when validating collectors

### Supported Pickup Types

- [x]  **Resource pickup** (souls, health, mana, gold, etc.)
- [x]  **Item pickup** (item data / progression unlocks)

### Future Features

- [ ]  Pickup VFX

---

# Unmanaged Modules

## Combat

## Combat Module

- [x]  CombatModule exists as a dedicated module
- [x]  Attack execution routed through CombatModule
- [x]  Primary / Secondary slot flow implemented
- [x]  Attack range validation implemented
- [x]  AttackInfo build pipeline implemented
- [x]  Target faction build pipeline implemented
- [x]  Damage roll implemented
- [x]  Crit roll implemented
- [x]  Delivery type routing implemented
- [x]  MeleeAttackModule implemented
- [x]  ProjectileAttackModule implemented
- [x]  Attack cooldown base module implemented
- [ ]  Verify actor attack origin placement is finalized for all actors
- [ ]  Separate orchestration concerns from actor input / FSM cleanly
- [ ]  Add clearer failure / result reporting if FSM needs attack success feedback
- [ ]  Verify all legacy attack drivers are retired after migration

Attack module cleanup

Attack effect cleanup

Stats - Seperate primary and secondary to sperate attack module except a common one
Seperate cooldown to stats instead in the attack module

Combat is already one of the most complete refactored areas: `CombatModule` builds `AttackInfo`, validates range, chooses executor by delivery type, and delegates to `MeleeAttackModule` or `ProjectileAttackModule`; the shared `AttackModule` base already handles cooldown locking.

## HitFeedback Module

- [x]  HitFeedbackModule exists
- [x]  Knockback configuration exists
- [x]  Flash configuration exists
- [x]  Shader-based visual target configuration exists
- [x]  Hit / death particle configuration exists
- [x]  Particle color override configuration exists
- [x]  Particle scale control exists
- [ ]  Verify damage receiver signal hookup is complete and stable
- [ ]  Verify flash / knockback / particles are fully driven from damage events only
- [ ]  Finalize death feedback behavior consistency across dummy / enemy / destroyable
- [ ]  Consider splitting generic hit feedback and actor-specific polish if module grows too large

I can confirm the module exists and already exposes knockback, flash, shader, and particle configuration surfaces. I could not fully inspect every method body from the web fetch, so I’m treating execution-level completion here as “likely in progress but not fully verified.”

## DamageReceiver Module

- [x]  DamageReceiverModule exists
- [x]  Hurtbox auto-wire implemented
- [x]  Damage intake flow isolated into module
- [x]  Invulnerability gate implemented
- [x]  Defense scaling implemented
- [x]  Minimum damage clamp implemented
- [x]  Target faction validation implemented
- [x]  damaged signal implemented
- [x]  blocked signal implemented
- [x]  died signal implemented
- [ ]  Verify all actors receive damage only through DamageReceiverModule
- [ ]  Review blocked semantics for non-damage hits vs invuln hits if needed
- [ ]  Remove any remaining direct health mutation outside stats / receiver path

DamageReceiverModule is already functionally refactored: it listens to `Hurtbox`, validates target faction, applies defense scaling, handles invulnerability time, and emits damage / blocked / died signals.

## Hitbox Module

- [x]  Hitbox module exists
- [x]  AttackInfo-driven collision mask setup implemented
- [x]  Optional repeated damage interval implemented
- [x]  Shape injection supported
- [x]  receive_hit pipeline into hurtbox implemented
- [ ]  Add clearer duplicate-hit policy if needed per target / per attack
- [ ]  Verify collision setup covers all factions you will need later

Hitbox already works as a reusable module and configures collision masks from `AttackInfo.target_factions`, with optional repeated pulses via timer.

## Hurtbox Module

- [x]  Hurtbox module exists
- [x]  Stats-driven collision layer setup implemented
- [x]  Enabled toggle implemented
- [x]  receive_hit signal handoff implemented
- [ ]  Verify all actors auto-bind owner stats consistently
- [ ]  Remove any remaining ad-hoc damage entry points

Hurtbox is already cleanly separated and emits `get_hit(attack_info)` into the receiver pipeline, with faction-based collision layer setup from owner stats.

## Detection Module

- [x]  DetectionModule exists as a dedicated module
- [x]  Detection area handled as module node
- [x]  Radius-based detection implemented
- [x]  Auto-created / auto-managed CircleShape2D supported
- [x]  Target entered / exited / changed signals implemented
- [x]  Target list query implemented
- [x]  Closest target query implemented
- [x]  Optional line-of-sight query implemented
- [x]  Entity cleanup on tree exit implemented
- [ ]  Add faction / stats-based target filtering at module level
- [ ]  Add ally / enemy policy so player, enemy, and armies can share one module cleanly
- [ ]  Add optional priority rules beyond closest target
- [ ]  Verify detection feeds player auto-attack flow cleanly
- [ ]  Verify detection does not rely on legacy detectbox / enemy scanner anymore

Detection is already much more than a stub: it tracks targets, exposes change signals, supports closest-target lookup, and can optionally filter by line of sight. What it does **not** yet appear to do is faction-aware filtering by itself; right now it primarily collects `Hurtbox` owners in range.

## Health Bar Module

- [x]  HealthBarModule exists
- [x]  Stats binding / unbinding implemented
- [x]  Full / damage / under bar flow implemented
- [x]  Damage delay timer implemented
- [x]  Damage tween animation implemented
- [x]  Heal catch-up behavior implemented
- [x]  Hide-when-full option implemented
- [x]  Hide-when-dead option implemented
- [ ]  Verify all actors use the same bar scene / binding pattern
- [ ]  Add world-space vs UI-space policy if both are needed
- [ ]  Keep health display module independent from gameplay logic

HealthBarModule is already substantially done: it binds to stats, updates three bars, and animates delayed damage-bar catch-up through timer + tween.

## Communication Module

- [x]  CommunicationModule exists
- [x]  Basic ally broadcast implemented
- [x]  Group-based alert propagation implemented
- [x]  Range-limited receive handling implemented
- [ ]  Replace simple group broadcast with final communication system design
- [ ]  Integrate with shared visibility / target knowledge rules
- [ ]  Standardize how enemies / armies consume external targets

Communication is present, but still looks minimal: group-based ally alerts with range filtering and optional owner callback handling. This feels prototype-level rather than final framework-level.

## Placement Module

- [x]  SpawnContext exists
- [x]  SpawnPoint exists
- [x]  SpawnPoint warning flow implemented
- [x]  Spawn root resolution implemented
- [x]  Spawn action execution hook implemented
- [ ]  Implement Placer beyond empty stub
- [ ]  Finalize placement pipeline for dungeon pre-placed vs dynamic spawn use cases
- [ ]  Verify SpawnAction ecosystem is fully wired to placement plans

Placement is partially refactored: `SpawnContext` and `SpawnPoint` are real and usable, but `placer.gd` is still just `extends Node`, so this area is clearly incomplete.

## Damage Numbers

- [x]  DamageNumber module / scene logic exists
- [x]  Crit style support exists
- [x]  Pop + float + fade animation exists
- [ ]  Add manager / aggregation / throttling layer if still planned

I could confirm a `damage_numbers` folder and a `DamageNumber` implementation, but not a verified manager script from the paths I checked.

## Stats System

- [ ]  Stats system completion
    - [x]  Basic attributes
    - [x]  Current attributes
    - [x]  Damage review
    - [ ]  Buff system
        - [ ]  Buff data structure (id, duration, stacks)
        - [ ]  Add / remove buff API
        - [ ]  Tick / expire (optional for 0.1.0)
        - [ ]  Recalculate integration
    - [x]  Recalculate stats

## Audio

### Core System

- [x]  **AudioManager**
    - [x]  Player pooling
    - [x]  Bus routing
    - [x]  Global playback API
    - [x]  Event-based playback (`play_event`)

### Playback Handlers

- [x]  **SoundHandler**
    - [x]  2D spatial SFX playback
    - [x]  SFX player pool
    - [x]  rate limiter / spam protection
    - [x]  world position playback
- [x]  **MusicHandler**
    - [x]  Music player
    - [x]  restart / ignore duplicate music
    - [x]  start time support

### Audio Events

- [x]  **AudioEvent (base)**
    - [x]  stream list
    - [x]  random stream selection
    - [x]  avoid repeat
    - [x]  pitch control
    - [x]  random pitch
    - [x]  volume control
    - [x]  bus configuration
- [x]  **SpatialAudioEvent**
    - [x]  world SFX playback
    - [x]  limiter configuration
    - [x]  default SFX bus
- [x]  **UiAudioEvent**
    - [x]  UI sound playback
    - [x]  default UI bus
- [x]  **MusicAudioEvent**
    - [x]  music playback configuration
    - [x]  restart policy
        - [x]  restart_if_same

### Future Improvements (Low Priority)

- [ ]  editor validation for empty stream list *(optional)*
- [ ]  weighted random streams
- [ ]  audio variation presets
- [ ]  fade in / fade out helpers
- [ ]  music crossfade
- [ ]  positional follow target
- [ ]  audio debug overlay

## Hit Feedback

- [x]  Enemy hit VFX
- [x]  Enemy hit SFX
- [x]  Damage flash effect

## Formation

- [x]  Dense formation
- [x]  Grid formation system
- [ ]  Renew grid foramtion systems to circle

## World and Minimap

- [x]  Dungeon generation
- [x]  Minimap
- [x]  Player on minimap
- [x]  Enemy on minimap
- [ ]  General world to dungeon and open world with minimap module

## Spawn System

- [x]  Area with spawner
- [x]  Trigger by player inpu

---

# Future Modules

## VFX Manager prototype

- [ ]  VFX Manager prototype
    - [ ]  Effects root
    - [ ]  Spawn helper
    - [ ]  Scene cleanup
    - [ ]  Layer / space policy (global vs local)
- [ ]  VFX throttling
    - [ ]  Max spawn per frame
    - [ ]  Max spawn per effect type
    - [ ]  Skip low priority effects
    - [ ]  Degrade policy (cheap variant / skip)
- [ ]  HitFeedbackEvent resource
    - [ ]  severity
    - [ ]  damage
    - [ ]  hit direction
    - [ ]  crit flag
    - [ ]  killed flag
    - [ ]  camera impulse
    - [ ]  sfx key
    - [ ]  particle override
    - [ ]  attach_to_target flag (optional)
    - [ ]  target_node_path or target_ref (optional)

## Destroyable

- [ ]  Polish
    - [ ]  Destroy signal
    - [ ]  Hit feedback
    - [ ]  Death particles
    - [ ]  Assign object_id / room_id (for mission tracking)

## Button

- [ ]  Press detection
- [ ]  button_id
- [ ]  one_shot
- [ ]  emit pressed signal
- [ ]  Assign room_id (for mission tracking)

## Extraction point

- [ ]  Area trigger
- [ ]  Hold timer
- [ ]  Cancel when leave
- [ ]  Emit extraction_completed
- [ ]  Assign room_id (for mission tracking)

## Summon

- [ ]  Summon system
    - [ ]  Just spawn random thing first
    - [ ]  UI
- [ ]  Focus on spawn armies? bridge?
- [ ]  Show summon slots
- [ ]  Show cooldown
- [ ]  Show summon queue

## Soul

- [ ]  Real Soul stats
- [ ]  Spend soulfor summon
- [ ]  Mana restoration
    - [x]  Soul orb drop from enemies
    - [x]  Absorb mana orb on pickup
    - [ ]  Switchable: Mana regeneration over time
- [ ]  VFX
    - [ ]  Mana particle travel to player
    - [ ]  Mana absorb visual feedback
- [ ]  SFX
    - [ ]  Mana pickup sound
    - [ ]  Mana absorb sound

## Camera System

- [ ]  Camera Manager
    - [ ]  Camera shake
    - [ ]  Camera impulse
    - [ ]  Camera zoom
    - [ ]  Camera focus direction

## Scene System

- [ ]  Scene Manager
    - [ ]  Scene transition
    - [ ]  Scene loading
    - [ ]  Scene cleanup
    - [ ]  Cleanup hook for VFXManager

## Dialog System

- [ ]  Simple dialog system
    - [ ]  Show dialog text box
    - [ ]  Display single line text
    - [ ]  Advance dialog with key press
    - [ ]  Optional auto close after last line
- [ ]  Dialog trigger
    - [ ]  Trigger dialog by event
    - [ ]  Trigger dialog by script call

## Run System

### Objective Framework

- [ ]  Base objective
    - [ ]  Objective state (active / completed)
    - [ ]  Emit `objective_completed`
    - [ ]  Provide objective text for HUD
- [ ]  Objective manager
    - [ ]  Register active objective
    - [ ]  Listen to EventBus
    - [ ]  Forward events to objective
    - [ ]  Emit objective completion signal
- [ ]  Objective HUD
    - [ ]  Show current objective text
    - [ ]  Update when objective changes
    - [ ]  Hide when no objective

### Objective Types

- [ ]  Kill quota objective
    - [ ]  Track `enemy_killed`
    - [ ]  Complete when target reached
- [ ]  Kill boss objective
    - [ ]  Track boss alive count
    - [ ]  Complete when all bosses dead
- [ ]  Extraction objective
    - [ ]  Activate extraction point
    - [ ]  Hold timer to extract
    - [ ]  Emit `extraction_completed`

### Run Flow Controller

Controls **run progression**, not objective logic.

- [ ]  Start run
- [ ]  Assign first objective
- [ ]  Objective completed → spawn boss
- [ ]  Boss killed → enable extraction
- [ ]  Extraction finished
    - [ ]  End run
    - [ ]  Send rewards
- [ ]  Player choice
    - [ ]  Continue fighting
    - [ ]  Extract and finish run

### Future work

- [ ]  Additional objective types
- [ ]  Multiple simultaneous objectives
- [ ]  Objective chains
- [ ]  Run modifiers

## Unlock / progression system

### Core

- [ ]  Dragon soul item
- [ ]  Summon unlock system
    - [ ]  Check unlock requirement
    - [ ]  Unlock summon
    - [ ]  Persist unlocked summons
- [ ]  Save / load progression
    - [ ]  Unique Souls Include
    - [ ]  Unlocks

## Telegraph Module

### Core

- [ ]  Enable / disable telegraph system
- [ ]  Spawn telegraph visual
- [ ]  Remove telegraph visual
- [ ]  Clear all active telegraphs

### Target Indicators

- [ ]  Lock-on marker on target
- [ ]  Target tracking indicator (follows moving target)
- [ ]  Target countdown indicator

### Area Warnings

- [ ]  Circular AOE preview
- [ ]  Rectangular / line AOE preview
- [ ]  Directional cone preview
- [ ]  Radius scaling preview

### Attack Direction Indicators

- [ ]  Rush / charge direction indicator
- [ ]  Sweep / slash direction indicator
- [ ]  Beam / laser line preview

### Continuous AOE

- [ ]  Rotating / spiral AOE indicator
- [ ]  Expanding AOE indicator
- [ ]  Pulsing AOE indicator

### Timing Feedback

- [ ]  Countdown ring
- [ ]  Flash warning before attack
- [ ]  Telegraph fade out when attack begins

### Runtime Control

- [ ]  Cancel telegraph
- [ ]  Update telegraph position
- [ ]  Update telegraph direction
- [ ]  Update telegraph size

### Multi Telegraph Support

- [ ]  Multiple simultaneous telegraphs
- [ ]  Telegraph layering / priority
- [ ]  Replace existing telegraph

## Debug Autoload

### Core

- [x]  Debug enable / disable switch
- [x]  Debug logging
- [x]  Debug warnings / invalid checks

### Gameplay Cheats

- [ ]  God mode
- [ ]  No cooldown
- [ ]  Free resources
- [ ]  Spawn entity
- [ ]  Kill all enemies

### Runtime Tools

- [ ]  Hotkey debug actions
- [ ]  Debug console
- [ ]  Command execution system

---

# Player

### Player

- [ ]  Migrate legacy movement system to MovementModule
- [ ]  Migrate legacy attack component flow to CombatModule
- [ ]  Migrate legacy animation control to AnimationModule
- [ ]  Migrate legacy detectbox / enemy scanner to DetectionModule
- [ ]  Migrate legacy damage receiving flow to DamageReceiverModule
- [ ]  Migrate legacy hit reaction / flash / knockback / particles to HitFeedbackModule
- [ ]  Remove direct legacy gameplay-driving components from Player
- [ ]  Keep Player focused on input, orchestration, module binding, and top-level actor rules

This remains a migration target, not something I can mark finished from `common/modules` alone. The modules exist, but that does not prove Player has fully handed control over to them yet. The repo still contains `_legacy/animation`, `_legacy/detectbox`, `_legacy/enemy_scanner`, and `_legacy/movement`, so migration is clearly not fully retired.

### Player StateMachine

- [ ]  Player StateMachine
- [ ]  Keep FSM focused on action flow only
- [ ]  Remove direct gameplay calculation responsibility from states
- [ ]  Remove direct animation system responsibility from states
- [ ]  Improve transition safety and robustness
- [ ]  Support clean state enter / exit / update flow
- [ ]  FSM for action
- [ ]  idle
- [ ]  move
- [ ]  attack
- [ ]  roll / dodge

I would keep this section mostly unresolved for now because this request was to inspect current refactored modules, and the module layer does not by itself prove FSM migration completeness. What **is** clear is that the module layer is now strong enough to support the FSM being reduced to action flow only.

---

# Enemy

- [ ]  Enemy migration to Module system
    - [ ]  Replace legacy Component
    - [ ]  Apply module structure used by Dummies
    - [ ]  Verify DamageReceiverModule
    - [ ]  Verify HitFeedbackModule
    - [ ]  Standardize VisualGroup (AnimationPlayer/Tree placement)
- [ ]  Enemy AI rewrite
    - [ ]  Replace FSM with Beehave
    - [ ]  Idle
    - [ ]  Wander
    - [ ]  Chase
    - [ ]  Attack
    - [ ]  Back / disengage
- [ ]  Aggro Range, Deaggro Range, Reach Range Seperate

---

# Armies(Summons)

- [ ]  Armies migration to Module system
    - [ ]  Replace legacy Component
    - [ ]  Verify attack module
    - [ ]  Verify movement module
- [ ]  Army summon system
    - [ ]  Integrate with summon system
        - [ ]  Press 1-4 summon
        - [ ]  Shift + 1-4 cancel summon
        - [ ]  C reset summon stack
        - [ ]  Summon cooldown
        - [ ]  Summon cast time
    - [ ]  Army card resource
    - [ ]  Summon slot configuration
    - [ ]  Army composition minimal (scene + count)
- [ ]

---

## AI / Group Control Follow-up

- [ ]  Enemy Chase Integration
    - [ ]  Enemy chase uses `follow_target_node()`
    - [ ]  Enemy attack decision stays actor / AI side via attack range check
    - [ ]  Enemy stops path motion when entering attack range
- [ ]  Army / Formation Control
    - [ ]  Group movement uses controller-side slot assignment
    - [ ]  Army units use `move_to(slot_position)` instead of direct follow-to-center
    - [ ]  Add standalone army / formation controller later if needed

---

# Misc

### Cleanup / Big Target Checklist

- [ ]  Player fully migrated to module-based architecture
- [ ]  Legacy player components no longer drive gameplay
- [ ]  Player root only handles orchestration and actor-level rules
- [ ]  Player action flow fully controlled by StateMachine
- [ ]  Modules are clearly separated by responsibility
- [ ]  Old player systems retired from _legacy after replacement is stable
- [ ]  Player architecture aligned with dummy/module refactor direction

The only one I would consider close to done here is responsibility separation at the module layer itself. The migration / retirement / orchestration goals still depend on actor-side adoption, not only module existence.

## Optional non-core module notes

###

### Projectile Base

- [x]  Projectile runtime entity exists
- [x]  Projectile movement / collision cleanup exists
- [x]  ProjectileAttackEffect hookup exists
- [ ]  Add richer projectile collision / hit policy if needed later

Projectile support is present as a separate runtime entity, which matches your refactor direction of real attack entities instead of overloading one effect path.

If you want, I can turn this into a tighter paste-ready markdown checklist with only the final cleaned sections and no commentary.

---

# **第二部分**

# Demo 必須完成（Itch.io 上架）

這是 **10分鐘完整體驗流程**

---

# Demo Content

- [ ]  Arena map - 1600x1600 map
- [ ]  Enemy spawn pacing
- [ ]  Basic enemy types (2~3)

---

# Army Demo Content

- [ ]  Slime army
- [ ]  Archer army
- [ ]  Ork army
- [ ]  Summon limits

---

# Boss

- [ ]  Dragon boss
    - [ ]  Fire attack
    - [ ]  Charge / swipe
    - [ ]  Death event

---

# Demo Flow

- [ ]  Player start setup
    - [ ]  Spawn player
    - [ ]  Lock player min-HP to 1
    - [ ]  Enable god mode (prevent death)
- [ ]  Initial UI state
    - [ ]  Show summon slots
    - [ ]  All summon slots disabled
    - [ ]  No mana available

---

- [ ]  Intro dialog
    - [ ]  Explain combat
    - [ ]  Tell player to destroy chest
    - [ ]  Drop mana orbs

---

- [ ]  Mana drop tutorial
    - [ ]  Dialog explain chest or enemies can drop mana orbs
    - [ ]  Player absorbs mana
    - [ ]  Summon slots become available

---

- [ ]  Summon tutorial dialog
    - [ ]  Summon 4 Slimes
    - [ ]  Summon 2 Archers
    - [ ]  Summon 1 Ork

---

- [ ]  Progress objective
    - [ ]  Fill progress by killing enemies
    - [ ]  Allow additional summons

---

- [ ]  Boss spawn
    - [ ]  Spawn Dragon boss
    - [ ]  Trigger boss dialog

---

- [ ]  Dragon demonstration
    - [ ]  Dragon kills multiple army units
    - [ ]  Enable mana regeneration

---

- [ ]  Player boss encounter
    - [ ]  Dragon attacks player
    - [ ]  Player HP locked to 1 (cannot die)

---

- [ ]  Boss defeat
    - [ ]  Player defeats dragon
    - [ ]  Trigger dragon unlock dialog

---

- [ ]  Unlock dragon summon
    - [ ]  Enable dragon summon slot

---

- [ ]  Demo ending
    - [ ]  Disable HP lock
    - [ ]  Enable chaos spawn mode
    - [ ]  Allow player to summon dragon
    - [ ]  Let player massacre enemies freely

---

# **第三部分**

# Itch.io 後續更新

---

# Content Expansion

- [ ]  New enemies
- [ ]  More army types
- [ ]  More maps

---

# Systems

- [ ]  Level system
- [ ]  XP system
- [ ]  Armies cards system
- [ ]  Formation System (advanced)
- [ ]  Change to order system like mount and blade
- [ ]  ~~Loose formation~~
- [ ]  ~~Custom formation~~
    - [ ]  ~~8 captain groups~~
    - [ ]  ~~Sub group type~~
    - [ ]  ~~Custom formation layout~~
- [ ]  Communication system (replace visibility sharing)
    - [ ]  Share visible enemies in army
    - [ ]  Share visible enemies in group
    - [ ]  Event communication
    - [ ]  Replace old visibility references

---

# Gameplay

- [ ]  Army balance
- [ ]  Boss balance
- [ ]  Mana economy tuning

---

# **第四部分**

# Steam Page 前

---

# Menu

- [ ]  Main menu
    - [ ]  Start
    - [ ]  Options
    - [ ]  Quit

---

# Options

- [ ]  Audio volume
- [ ]  Resolution
- [ ]  Fullscreen

---

# Pause Menu

- [ ]  Resume
- [ ]  Restart run
- [ ]  Quit run

---

# Presentation

- [ ]  Trailer recording
- [ ]  Steam screenshots
- [ ]  Capsule art

---

# **第五部分**

# Steam Demo 前

---

# Save System

- [ ]  Save settings
- [ ]  Save unlocks
- [ ]  Continue run (optional)

---

# Polish

- [ ]  Controller support
- [ ]  UI polish
- [ ]  Visual clarity tuning

---

# Performance

- [ ]  VFX optimization
- [ ]  Army performance tuning

---

# 第六部分

# Steam Early Access 前

---

# Major Systems

- [ ]  Campaign system
- [ ]  Run reward
- [ ]  Artifact system
- [ ]  Army storage

---

# Content

- [ ]  More bosses
- [ ]  More maps
- [ ]  More army types

---

# Meta Progression

- [ ]  Unlock system
- [ ]  Upgrade system
- [ ]  Run rewards

---

# **研究部分**

---

# World Generation Research

- [ ]  Dungeon generation addons

# Damage - Later polish

*(Not required for demo)*

- [ ]  Hitstop
- [ ]  Advanced VFX manager
- [ ]  Damage number merging
- [ ]  Damage number priority system
- [ ]  Weapon system separation from Stats

---