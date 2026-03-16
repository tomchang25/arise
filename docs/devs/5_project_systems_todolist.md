# Project Systems Todolist

---

# Refactored Modules

## Stats System

### Core Features

- [x]  **Basic attributes** - base_max_health, base_max_mana, base_damage, base_defense, base_speed
- [x]  **Runtime attributes** - current_* computed values exposed after recalculation
- [x]  **Stat recalculation** - recalculate_stats() triggered on every base setter
- [x]  **Damage / health handling** - health setter with signal emit and clamp
- [x]  **Resource stats support** - health, mana, souls, gold each with change signals
- [x]  **Weapon layer merged** - weapon_damage, weapon_crit_chance, weapon_crit_multiplier present as temporary merged fields
- [x]  **Faction enum** - PLAYER, ENEMY, NEUTRAL
- [x]  **AttackSlot enum** - PRIMARY, SECONDARY, SKILL_1, SKILL_2

### Robustness

- [x]  **Clamp runtime values** - values clamped to valid range on set
- [x]  **Sync resources after recalculation** - runtime resources kept valid
- [x]  **Resource helpers** - add / spend / recover via stats setters and signals
- [x]  **Pickup-driven resource checks** - stats.souls, stats.mana exposed for pickup validation

### Future Features

- [ ]  **Buff system** - buff data structure, add/remove API, duration/expire, recalculation integration
- [ ]  **Weapon layer separation** - remove temporary weapon fields, drive via proper weapon system

---

## Movement Module

### Core Features

- [x]  **CharacterBody2D isolation** - movement execution isolated inside module
- [x]  **Manual velocity** - set_manual_velocity() input supported
- [x]  **Path velocity** - path velocity input from NavigationModule supported
- [x]  **Mode switching** - set_manual_mode() / set_path_mode() supported
- [x]  **Stop helpers** - stop_manual_motion() / stop() implemented

### Advanced Movement

- [x]  **Acceleration / deceleration** - smoothing implemented
- [x]  **Knockback channel** - apply_knockback(impulse, cap) with velocity channel
- [x]  **Knockback decay** - friction-based decay per frame

### Future Features

- [ ]  **Dash / roll override** - temporary movement override during dash / roll
- [ ]  **Dash-to-destination** - dash toward a point
- [ ]  **Collision ignore** - ignore actors and optionally world during dash
- [ ]  **Dash priority** - dash overrides manual / path / knockback cleanly
- [ ]  **Clean restore** - movement state restored on dash end

---

## Pathfinding Module

### Core Features

- [x]  **NavigationAgent2D isolation** - planning isolated inside module
- [x]  **Global target position** - move_to(position) supported
- [x]  **Follow target node** - follow_target_node(node) supported
- [x]  **Path velocity wired** - output piped into MovementModule
- [x]  **Signals** - navigation_finished and target_changed emitted
- [x]  **Stop helpers** - stop() and clear_path() implemented

### Path Update Flow

- [x]  **Target refresh interval** - configurable recompute rate
- [x]  **Continuous recompute** - handled automatically by module
- [x]  **Arrive distance** - configurable
- [x]  **Max speed** - configurable
- [x]  **Anti-jitter guard** - repath tolerance implemented

### Avoidance / Safety

- [x]  **NavigationAgent avoidance** - optional toggle
- [x]  **Safe velocity** - velocity_computed callback supported
- [x]  **Clears on disable** - path velocity cleared when module disabled or target gone
- [x]  **Missing dependency safety** - module handles null dependencies

### Testbed

- [x]  **Debug draw** - target and path state visualized
- [x]  **Testbed scenes** - single and group dummy flow validated
- [x]  **Obstacle validation** - static obstacle and avoidance separation verified

### Future Features

- [ ]  **Stuck handling** - handle agents stuck near goal due to avoidance or crowd pressure, accept near-goal arrival or retry path

---

## Animation Module

### Core Features

- [x]  **Dedicated module** - AnimationModule exists
- [x]  **Playback cache** - AnimationTree playback cache implemented
- [x]  **State travel** - travel_to_state() helper implemented
- [x]  **Blend position** - set_animation_direction() helper implemented
- [x]  **Time scale** - set_time_scale() helper implemented
- [x]  **Facing cache** - get_last_direction() implemented
- [x]  **Signal bridge** - animation_finished forwarded from AnimationTree

### Module Safety

- [x]  **Enabled switch** - explicit enable / disable supported
- [x]  **Auto-wire** - actor / animation_tree auto-discovered on ready
- [x]  **Runtime reset** - state cleared when disabled
- [x]  **Validation** - missing playback / tree / path warnings implemented
- [x]  **Standardized API** - naming consistent with other modules

---

## Loot Module

### Core Features

- [x]  **Loot roll system** - drop tables support weighted selection, chance rolls, and amount rolls
- [x]  **Drop results** - roll results converted into structured LootDropResult data
- [x]  **Spawning pipeline** - trigger from one call, spawn with scatter, emit loot_dropped
- [x]  **Pickup integration** - loot module integrated with pickup module

### Robustness

- [x]  **Validate drop entries** - missing pickup scene and missing reward data caught
- [x]  **Validate empty table** - empty or broken drop table handled

### Multiple Tables

- [x]  **Independent tables per profile** - LootDropProfile holds multiple LootDropTables
- [x]  **Independent roll per table** - each table rolls separately
- [x]  **Weight isolation** - entry weights only compete within same table
- [x]  **Resource / item / rare split** - supported as separate table setup

### Future Features

- [ ]  **Shared drop entries** - reuse common entries across tables to reduce duplication
- [ ]  **Reward scaling** - enemy-side amount scaling for level, tier, or rank
- [ ]  **Elite / boss bonus table** - optional extra table without replacing base profile
- [ ]  **Luck modifier** - rarity / luck stat via buff system

profile = composition, table = independent roll bucket, entry = base reward row, enemy = runtime scaling input.

---

## Item / Resources System

### Core Features

- [x]  **Shared reward data** - ResourceData and item data define reward identity
- [x]  **Reusable reward data** - same soul/gold/mana/health data reused by loot and pickups
- [x]  **Separate reward types** - item rewards and resource rewards handled differently
- [x]  **Soul orb** - soul_orb_data.tres exists (id = soul_orb, amount_per_unit = 20)

### Resource Rewards

- [x]  **Gold** - adds currency
- [x]  **Mana orb** - restores mana-related value
- [x]  **Health orb** - restores health-related value
- [x]  **Soul orb** - adds soul resource

### Future Features

- [ ]  **Item runtime flow** - items support progression / inventory-style rewards
- [ ]  **Shared base class** - if item and resource types accumulate common behavior

---

## Pickup Module

### Core Features

- [x]  **Pickup interaction** - actors trigger pickup on area enter
- [x]  **Reward application** - pickup applies RewardData to collector stats
- [x]  **Self-consume** - pickup queues free after collection
- [x]  **Loot integration** - loot drop spawns pickups correctly
- [x]  **Magnet / auto-collect** - configurable radius
- [x]  **Lifetime / auto-despawn** - pickup frees itself after timeout
- [x]  **Full-stat guard** - no pickup if collector stats already full
- [x]  **Sound hooks** - pickup sound event triggered on collect

### Robustness

- [x]  **Validate configuration** - missing reward data and scene setup caught
- [x]  **Duplicate trigger guard** - prevented
- [x]  **Invalid collector guard** - validated before applying reward
- [x]  **Hurtbox → body order** - validated when confirming collector

### Supported Types

- [x]  **Resource pickup** - souls, health, mana, gold
- [x]  **Item pickup** - item data / progression unlocks

### Future Features

- [ ]  **Pickup VFX** - visual on collect
- [ ]  **Magnet bug** - magnet continues pulling even when collector can't collect; pull starts before collection state confirms

---

## Spawn System

### Core Features

- [x]  **SpawnAction abstraction** - extendable spawn behavior base resource
- [x]  **SpawnExecutor abstraction** - unified runtime execution
- [x]  **SpawnPackedSceneAction** - spawns single PackedScene with parent, offset, scatter, rotation
- [x]  **SpawnFromWeightedTableAction** - picks scene from WeightedSceneTable then forwards
- [x]  **SpawnPoint** - scene anchor emits placed(node) after spawn
- [x]  **WarningSpawnPoint** - shows telegraph, waits warning_time, then spawns and frees itself
- [x]  **SpawnContext** - runtime data: parent, source node, RNG seed, metadata
- [x]  **SpawnResult** - structured output: success, node, position, failure reason
- [x]  **SpawnRequest API** - setup_direct() / setup_warning() high-level entry points
- [x]  **SpawnPositionFinder** - valid position search inside radius or annulus
- [x]  **SpawnPositionValidator** - bounds, exclusion zones, screen exclusion, physics overlap
- [x]  **SpawnRegistry** - weak-reference tracker for spawned nodes, supports bulk cleanup

### Spawn Tables / Encounters

- [x]  **WeightedSceneTable** - random weighted scene selection
- [x]  **EnemyEncounterProfile** - group-based enemy spawn selection
- [x]  **Spawn parent routing** - spawned entities attach to correct world parent

### Robustness

- [x]  **Validate configuration** - missing action, parent, scene, invalid table/context all caught
- [x]  **Failure reporting** - SpawnResult returns blocked reason instead of silent null
- [x]  **Prevent invalid execution** - broken actions cannot silently fail

### Future Features

- [ ]  **Spawn VFX hooks** - visual on spawn
- [ ]  **Spawn SFX hooks** - sound on spawn
- [ ]  **Spawn burst / multi-spawn patterns** - grouped instant spawn
- [ ]  **Custom warning scene per request** - override telegraph per call
- [ ]  **Typed failure reasons** - enum error codes in SpawnResult
- [ ]  **Registry source grouping / tagging** - tag groups for bulk ops
- [ ]  **Collision / nav validation** - ensure spawn position is nav-mesh reachable

---

## DespawnController

### Core Features

- [x]  **Distance-based despawn** - entities removed when exceeding despawn_distance from tracked_target
- [x]  **Play area rect despawn** - entities removed when leaving play_area_rect bounds
- [x]  **SpawnRegistry integration** - only despawns registered nodes
- [x]  **Cleanup interval** - periodic invalid entry cleanup via configurable cleanup_interval
- [x]  **Register / unregister API** - register_spawned(node) and unregister_spawned(node)
- [x]  **Debug draw** - despawn radius ring and play area rect visualized

### Robustness

- [x]  **Enabled switch** - process skipped when disabled
- [x]  **Null target warning** - warns if use_distance_limit is true but tracked_target unset
- [x]  **Safe despawn** - is_instance_valid check before removing

### Future Features

- [ ]  **Progressive deletion** - Minecraft-like gradual fade / dissolve instead of instant queue_free
- [ ]  **Combat guard** - prevent despawn while entity is actively in combat
- [ ]  **Batch optimization** - avoid despawning too many entities in a single frame

---

## Encounter Controller

### Core Features

- [x]  **EncounterController** - manages round-based arena encounter lifecycle
- [x]  **Round state machine** - IDLE / ROUND_ACTIVE / ROUND_CLEARED states
- [x]  **EncounterConfig** - drives group count, spawn table, pacing interval
- [x]  **Spawn position resolver** - caller-injected Callable resolves valid positions
- [x]  **Group tracking** - active EnemyGroup array tracked through spawn to depletion
- [x]  **Signals** - encounter_started, round_started, round_cleared, group_spawned, group_depleted, group_removed
- [x]  **start_next_round()** - explicit advance after ROUND_CLEARED

### Pacing

- [x]  **Spawn interval** - configurable rate from EncounterConfig
- [x]  **Groups-to-kill quota** - round clears when target kill count reached
- [x]  **force_tick()** - immediate pacing tick for testing / debugging

### Robustness

- [x]  **Config validation** - invalid configs rejected before start
- [x]  **end() cleanup** - all active groups cleared and state reset
- [x]  **Duplicate start guard** - end() called before re-start

### Future Features

- [ ]  **Difficulty scaling** - scale enemy stats or counts per round
- [ ]  **Multi-round config** - drive multiple rounds from one resource
- [ ]  **Boss encounter integration** - dedicated boss round type
- [ ]  **Encounter difficulty scaling**
- [ ]  **Biome-based encounter tables**
- [ ]  **Partial kill credit** - if player killed at least one member before group despawns, count as a depleted group (or award fractional credit) rather than silently discarding

---

# Unmanaged Modules

## Combat Module

### Core Features

- [x]  **CombatModule** - dedicated module exists
- [x]  **Fire-and-forget API** - perform_attack(slot, target_position, auto_end)
- [x]  **Persistent API** - activate_attack(slot, dir) / deactivate_attack(slot)
- [x]  **Attack slot routing** - PRIMARY and SECONDARY slots supported
- [x]  **AttackData build** - delivery_type, damage roll, crit roll, target_factions, knockback built per slot
- [x]  **MeleeAttackModule** - fire-and-forget melee executor
- [x]  **ProjectileAttackModule** - fire-and-forget projectile executor
- [x]  **ContactAttackModule** - persistent contact hitbox executor
- [x]  **ChargeAttackModule** - persistent charge hitbox executor
- [x]  **Cooldown base** - FireAttackModule.locked + cooldown_timer handles locking
- [x]  **auto_end flag** - defer end_attack() to animation_finished if needed
- [x]  **Range validation** - target clamped to attack range when out of range

### Pending Cleanup

- [ ]  **Cooldown to Stats** - move per-slot cooldown values out of attack module into Stats
- [ ]  **Whiff / hit SFX split** - slash_audio fires on swing regardless of hit; add on-hit SFX path separate from the swing SFX
- [ ]  **Primary / secondary separation** - each slot drives its own executor without shared state bleed
- [ ]  **Attack origin verification** - finalize attack origin placement for all actors
- [ ]  **Legacy driver retirement** - verify all old attack components removed after migration

Four delivery types are fully wired: MELEE, PROJECTILE, CONTACT, CHARGE. Contact and Charge manage their own hitboxes and do not require an attack_scene.

---

## HitFeedback Module

### Core Features

- [x]  **HitFeedbackModule** - dedicated module exists
- [x]  **Knockback** - apply_knockback() driven by AttackData.knockback_force and knockback_dir
- [x]  **Flash effect** - shader overlay driven by damage events
- [x]  **Shader target** - configurable visual target node
- [x]  **Hit particles** - one-shot GPUParticles2D at owner position, rotated by attack direction
- [x]  **Death particles** - separate particle config for death feedback
- [x]  **Particle color / scale override** - configurable per actor
- [x]  **MovementModule integration** - knockback applied via movement_module.apply_knockback if available

### Pending

- [ ]  **Damage receiver hookup audit** - confirm signal chain complete across all actors
- [ ]  **Event-only guarantee** - flash / knockback / particles driven from damage signals only
- [ ]  **Death feedback consistency** - standardize across dummy, enemy, destroyable

---

## DamageReceiver Module

### Core Features

- [x]  **DamageReceiverModule** - dedicated module exists
- [x]  **Hurtbox auto-wire** - listens to hurtbox.get_hit signal
- [x]  **Invulnerability gate** - i-frames prevent repeated damage
- [x]  **Defense scaling** - incoming damage reduced by stats.current_defense
- [x]  **Minimum damage clamp** - floor of 1 applied
- [x]  **Faction validation** - rejects hits from non-target factions
- [x]  **Signals** - damaged(amount, new_health, info), blocked(info), died(info)

### Pending

- [ ]  **All-actor audit** - verify all actors receive damage only through this module
- [ ]  **Blocked semantics** - clarify non-damage hits vs invuln hits
- [ ]  **Direct mutation removal** - remove any remaining stats.health writes outside this module

DamageReceiverModule is the canonical damage entry point. Direct stats.health mutation elsewhere should be removed.

---

## Hitbox Module

### Core Features

- [x]  **Hitbox module** - exists as reusable module
- [x]  **Faction-driven collision mask** - collision layers set from AttackData.target_factions
- [x]  **Repeated damage interval** - optional pulse timer for persistent hitboxes
- [x]  **Shape injection** - custom CollisionShape2D injectable
- [x]  **Hit pipeline** - receive_hit forwarded into Hurtbox

### Pending

- [ ]  **Duplicate-hit policy** - per-target or per-attack dedup if needed
- [ ]  **Faction coverage audit** - verify all required factions covered

---

## Hurtbox Module

### Core Features

- [x]  **Hurtbox module** - exists as reusable module
- [x]  **Stats-driven collision** - collision layer set from owner Stats.faction
- [x]  **Enabled toggle** - disable to make actor temporarily unhittable
- [x]  **Signal handoff** - get_hit(attack_info) emitted into DamageReceiverModule

### Pending

- [ ]  **Actor binding audit** - verify all actors auto-bind owner stats consistently
- [ ]  **Ad-hoc damage removal** - remove any remaining direct damage paths that bypass hurtbox

---

## Detection Module

### Core Features

- [x]  **DetectionModule** - dedicated module exists
- [x]  **Radius-based detection** - auto-managed CircleShape2D via set_collision_radius()
- [x]  **Target signals** - target_entered, target_exited, target_changed
- [x]  **Target list query** - get_targets() available
- [x]  **Closest target query** - get_closest_target() available
- [x]  **Line-of-sight filter** - optional LOS check
- [x]  **Cleanup on exit** - entities removed from list on tree exit
- [x]  **Used by Player** - reach_detection drives auto-attack target selection

### Pending

- [ ]  **Faction filtering** - faction-based filtering at module level, not just Hurtbox presence
- [ ]  **Ally / enemy policy** - clean shared use by player, enemy, and armies from one module
- [ ]  **Priority rules** - target selection beyond just closest
- [ ]  **Legacy scanner retirement** - EnemyScanner still used in Army; not yet replaced

Detection currently collects Hurtbox owners in range. Faction filtering is caller-side. Army still uses the legacy EnemyScanner.

---

## Health Bar Module

### Core Features

- [x]  **HealthBarModule** - dedicated module exists
- [x]  **Stats binding** - bind(stats) and unbind() supported
- [x]  **Three-bar layout** - full bar, damage delay bar, under bar
- [x]  **Damage delay timer** - configurable delay before bar catches up
- [x]  **Tween animation** - damage bar animated via tween
- [x]  **Heal catch-up** - heals update bar immediately
- [x]  **Hide-when-full** - optional
- [x]  **Hide-when-dead** - optional

### Pending

- [ ]  **Actor binding audit** - verify all actors use same bar scene / binding pattern
- [ ]  **World-space vs UI-space policy** - add routing if both are needed
- [ ]  **Gameplay isolation** - module should contain no gameplay logic

---

## Alert Module

### Core Features

- [x]  **FactionAlertModule** - exists at `common/gameplay/ai/`
- [x]  **Faction group broadcast** - alert_allies() calls tree group by faction_group string
- [x]  **Range-limited receive** - on_broadcast_received() filters by distance to broadcast origin
- [x]  **Owner callback** - calls handle_external_target() on owner if method exists

### Pending

- [ ]  **Replace prototype** - group string broadcast is fragile; replace with proper faction-aware system
- [ ]  **Visibility integration** - integrate with shared visibility / target knowledge rules
- [ ]  **Standardize consumption** - define how enemies and armies act on received external targets
- [ ]  **Faction coupling** - faction_group is a raw string; should derive from owner Stats.faction

FactionAlertModule is prototype-level. It is not the final system.

---

## Placement Module

### Core Features

- [x]  **SpawnContext** - exists and used by spawn system
- [x]  **SpawnPoint** - scene anchor with warning flow
- [x]  **Spawn root resolution** - parent resolved from context
- [x]  **SpawnAction execution hook** - implemented

### Pending

- [ ]  **Placer implementation** - placer.gd is currently an empty stub (extends Node only)
- [ ]  **Placement pipeline** - dungeon pre-placed vs dynamic spawn use cases need design
- [ ]  **SpawnAction ecosystem wiring** - verify all action types fully wired to placement plans

Placement is partially refactored. SpawnContext and SpawnPoint are real and usable. The Placer itself is not implemented.

---

## Damage Numbers

### Core Features

- [x]  **DamageNumber** - module / scene logic exists
- [x]  **Crit style** - separate visual for crits
- [x]  **Pop / float / fade** - animation implemented

### Pending

- [ ]  **Manager / aggregation layer** - throttle, merge nearby numbers, priority system

---

## Audio

### Core System

- [x]  **AudioManager** - player pooling, bus routing, global playback, event-based play_event()
- [x]  **SoundHandler** - 2D spatial SFX, player pool, rate limiter, world position playback
- [x]  **MusicHandler** - music player, restart / ignore duplicate, start time support

### Audio Events

- [x]  **AudioEvent (base)** - stream list, random selection, avoid repeat, pitch, volume, bus config
- [x]  **SpatialAudioEvent** - world SFX playback with limiter, default SFX bus
- [x]  **UiAudioEvent** - UI sound playback, default UI bus
- [x]  **MusicAudioEvent** - music config, restart_if_same policy

### Future Features

- [ ]  **Weighted random streams** - per-entry weight in stream list
- [ ]  **Audio variation presets** - reusable preset resources
- [ ]  **Fade in / fade out helpers**
- [ ]  **Music crossfade**
- [ ]  **Positional follow target** - audio source that tracks a node
- [ ]  **Audio debug overlay**
- [ ]  **Editor validation** - warn on empty stream list *(low priority)*

---

## Hit Feedback

### Core Features

- [x]  **Enemy hit VFX** - particles on hit
- [x]  **Enemy hit SFX** - audio event on hit
- [x]  **Damage flash** - shader overlay on damage

---

## Formation

### Core Features

- [x]  **Dense formation** - close-packed unit layout
- [x]  **Grid formation** - grid-based slot assignment via ArmyHandler

### Pending

- [ ]  **Circle formation** - renew grid formation to circle-based layout

---

## World and Minimap

### Core Features

- [x]  **Dungeon generation** - DungeonGenerator with LEGACY_MST and OVERLAP_MERGE algorithms
- [x]  **Minimap** - exists
- [x]  **Player on minimap** - tracked
- [x]  **Enemy on minimap** - tracked

### Pending

- [ ]  **World abstraction** - generalize to support both dungeon and open world with shared minimap module

---

# Future Modules

## VFX Manager

### Core

- [ ]  **Effects root** - dedicated node for VFX parenting
- [ ]  **Spawn helper** - single call to spawn any VFX
- [ ]  **Scene cleanup** - auto-free on finish
- [ ]  **Space policy** - global vs local space routing

### Throttling

- [ ]  **Max spawn per frame** - cap to prevent frame spikes
- [ ]  **Max per effect type** - type-based cap
- [ ]  **Skip low priority** - degrade to cheap variant or skip

### HitFeedbackEvent Resource

- [ ]  **Event fields** - severity, damage, hit_direction, crit_flag, killed_flag, camera_impulse, sfx_key, particle_override, attach_to_target, target_ref

---

## Destroyable

### Polish

- [ ]  **Destroy signal** - emitted on death
- [ ]  **Hit feedback** - visual response to damage
- [ ]  **Death particles** - burst on destroy
- [ ]  **Object ID / room ID** - for mission and objective tracking

---

## Button

### Core

- [ ]  **Press detection** - area or input trigger
- [ ]  **button_id** - identifier for event routing
- [ ]  **one_shot** - single-use flag
- [ ]  **pressed signal** - emitted on activation
- [ ]  **room_id** - for mission tracking

---

## Extraction Point

### Core

- [ ]  **Area trigger** - player enters zone
- [ ]  **Hold timer** - must remain in zone for duration
- [ ]  **Cancel on leave** - timer resets if player exits
- [ ]  **extraction_completed signal**
- [ ]  **room_id** - for mission tracking

---

## Summon System

### Core

- [ ]  **Soul cost** - spend Stats.souls on summon
- [ ]  **Summon slot UI** - show slots, enable / disable based on soul count
- [ ]  **Cooldown display** - per-slot cooldown indicator
- [ ]  **Summon queue display** - queued summon visualized
- [ ]  **Army bridge** - summon spawns into ArmyHandler

---

## Soul System

### Core

- [ ]  **Real soul stats** - Stats.souls tracked; signal exists
- [ ]  **Spend soul for summon** - consume on summon action
- [x]  **Soul orb drop** - drops from enemies via loot module
- [x]  **Soul orb pickup** - absorbed by PickupCollectorModule on contact
- [ ]  **Switchable regen** - soul or mana regeneration over time toggle

### VFX / SFX

- [ ]  **Pickup travel VFX** - orb particle travels to player
- [ ]  **Absorb visual feedback**
- [ ]  **Pickup sound** - audio event on collect
- [ ]  **Absorb sound**

---

## Camera System

### Core

- [ ]  **CameraManager** - camera shake, impulse, zoom, focus direction

---

## Scene System

### Core

- [ ]  **SceneManager** - scene transition, loading, cleanup, VFXManager cleanup hook

---

## Dialog System

### Core

- [ ]  **Dialog box** - show / hide text box
- [ ]  **Single line display**
- [ ]  **Advance on key press**
- [ ]  **Auto close** - optional after last line
- [ ]  **Event trigger** - triggered by EventBus
- [ ]  **Script trigger** - triggered by direct call

---

## Run System

### Objective Framework

- [ ]  **Base objective** - state (active / completed), objective_completed signal, HUD text
- [ ]  **Objective manager** - register objective, listen EventBus, forward events, emit completion

### Objective HUD

- [ ]  **Show current text** - update on change, hide when no objective

### Objective Types

- [ ]  **Kill quota** - track enemy_killed, complete on target count
- [ ]  **Kill boss** - track boss alive count, complete when all dead
- [ ]  **Extraction** - activate point, hold timer, emit extraction_completed

### Run Flow Controller

- [ ]  **Start run** - initialize and assign first objective
- [ ]  **Objective → boss spawn** - on objective complete
- [ ]  **Boss → extraction** - enable extraction on boss kill
- [ ]  **End run** - send rewards and close
- [ ]  **Player choice** - continue fighting or extract

### Future Work

- [ ]  **Additional objective types**
- [ ]  **Multiple simultaneous objectives**
- [ ]  **Objective chains**
- [ ]  **Run modifiers**

---

## Unlock / Progression System

### Core

- [ ]  **Dragon soul item** - unique soul drop resource
- [ ]  **Summon unlock** - check requirement, unlock, persist
- [ ]  **Save / load** - unique souls and unlocks persisted

---

## Telegraph Module

### Core

- [ ]  **Enable / disable** - system-level toggle
- [ ]  **Spawn / remove visual** - per-telegraph lifecycle
- [ ]  **Clear all**

### Indicator Types

- [ ]  **Target lock-on** - lock marker, tracking indicator, countdown
- [ ]  **Area AOE** - circle, rectangle, cone, scaling radius
- [ ]  **Attack direction** - rush / charge line, sweep arc, beam line
- [ ]  **Continuous AOE** - rotating, expanding, pulsing
- [ ]  **Timing feedback** - countdown ring, flash warning, fade on attack start

### Runtime Control

- [ ]  **Cancel, reposition, resize, redirect** - per active telegraph
- [ ]  **Multi-telegraph** - simultaneous, layering / priority, replacement

---

## Debug Autoload

### Core

- [x]  **Enable / disable switch** - Debug.enabled flag
- [x]  **Logging** - Debug.log()
- [x]  **Warnings / validation** - Debug.warn()

### Gameplay Cheats

- [ ]  **God mode** - no damage taken
- [ ]  **No cooldown** - skip all cooldowns
- [ ]  **Free resources** - instant soul / mana / gold fill
- [ ]  **Spawn entity** - spawn arbitrary scene at cursor
- [ ]  **Kill all enemies** - instant clear

### Runtime Tools

- [ ]  **Hotkey debug actions** - F-key bindings for cheat actions
- [ ]  **Debug console** - in-game text input
- [ ]  **Command execution** - parse and dispatch console commands

---

# Player

## Player Actor

### Module Migration

- [x]  **MovementModule** - wired, set_manual_mode() on bind
- [x]  **AnimationModule** - wired, actor bound, animation_finished bridged
- [x]  **CombatModule** - wired, stats bound, perform_attack() used in attack state
- [x]  **DamageReceiverModule** - wired, hurtbox and stats bound, damaged and died connected
- [x]  **HitFeedbackModule** - wired, stats and damage_receiver bound
- [x]  **DetectionModule** - reach_detection wired, radius from stats.primary_attack_range
- [x]  **HealthBarModule** - bound via health_bar.bind(stats)
- [x]  **PickupCollectorModule** - wired, owner_body and stats assigned
- [ ]  **Legacy retirement** - _legacy/animation, _legacy/detectbox, _legacy/enemy_scanner, _legacy/movement still present in repo; not yet deleted

### Player StateMachine

- [x]  **Idle state** - implemented (player_idle_state.gd)
- [x]  **Move state** - walk / run, idle grace timer (player_move_state.gd)
- [x]  **Attack state** - perform_attack() called, attack_finished used (player_attack_state.gd)
- [x]  **Roll state** - roll_finished signal used (player_roll_state.gd)
- [ ]  **FSM cleanup** - remove direct gameplay calculation and animation control from states; states should only manage transitions and call Player API

Player FSM is functionally complete for the demo. All four states are implemented and wired. Legacy _legacy/ folders still exist in repo but Player does not drive gameplay through them. Full deletion is the remaining task.

---

# Enemy

## Enemy Actor

### Core

- [x]  **Module system migration** - CombatModule, MovementModule, NavigationModule, AnimationModule, DetectionModule, DamageReceiverModule, HitFeedbackModule all wired
- [x]  **Aggro / deaggro / reach ranges** - separate DetectionModule nodes for each range
- [x]  **Robust state transitions** - states use module APIs

### Enemy State Machine

- [x]  **Idle** - implemented
- [x]  **Chase** - implemented, uses follow_target_node()
- [x]  **Back** - implemented
- [x]  **Leash Back** - implemented
- [x]  **Attack** - implemented
- [x]  **Charge Windup** - locks direction toward player (enemy_charge_windup.gd)
- [x]  **Charge** - drives manual velocity, ends on wall or timer (enemy_charge.gd)
- [x]  **Charge Recovery** - stun duration, resumes chase or back (enemy_charge_recovery.gd)

### Future Work

- [ ]  **Data-driven setup** - import / export enemy config and auto-attach to modules
- [ ]  **Beehave migration** - replace FSM with Beehave behavior trees

---

# Armies (Summons)

## Army Actor

### Current State (Legacy — not yet migrated)

- [ ]  **MovementModule** - still uses legacy BaseMovement (_legacy/movement/base_movement.gd)
- [ ]  **AnimationModule** - still uses legacy BaseAnimation
- [ ]  **DetectionModule** - still uses legacy EnemyScanner
- [ ]  **CombatModule** - attack handler is commented out in army.gd; no attack wired
- [ ]  **ArmyHandler** - manages unit registration, shared vision, grid slots; functional but tied to legacy internals

### Target Migration

- [ ]  **Replace BaseMovement** - wire MovementModule
- [ ]  **Replace BaseAnimation** - wire AnimationModule
- [ ]  **Replace EnemyScanner** - wire DetectionModule
- [ ]  **Wire CombatModule** - verify attack module per army type

### Summon System (not yet built)

- [ ]  **Summon input** - press 1–4 to summon, Shift+1–4 to cancel, C to reset stack
- [ ]  **Soul cost** - consume Stats.souls on summon
- [ ]  **Cooldown / cast time** - per summon slot
- [ ]  **Army card resource** - defines composition (scene + count)
- [ ]  **Summon slot config** - which slots are unlocked
- [ ]  **Summon limits** - cap per army type

Army is the least migrated actor. The full legacy component stack (BaseMovement, BaseAnimation, EnemyScanner) is still live. ArmyHandler grid system works but depends on legacy army internals.

---

## AI / Group Control

### Enemy AI

- [ ]  **Chase audit** - verify all enemies use follow_target_node() not direct pathfinding calls
- [ ]  **Attack range gate** - enemy stops navigation cleanly when entering reach range
- [ ]  **Navigation stop on attack** - confirm path motion stops before attack executes

### Army / Formation

- [ ]  **Controller-side slot assignment** - group movement uses assigned grid slots, not follow-to-center
- [ ]  **move_to(slot_position)** - army units navigate to assigned slot position
- [ ]  **Standalone army controller** - if formation logic grows beyond ArmyHandler

---

# Misc

## Cleanup Checklist

- [x]  **Module layer clean** - all modules separated by responsibility
- [x]  **Player drives via modules** - Player does not use legacy components for gameplay
- [ ]  **Legacy folders retired** - _legacy/animation, _legacy/detectbox, _legacy/enemy_scanner, _legacy/movement still in repo
- [ ]  **Army migrated** - Army still on legacy component stack
- [ ]  **Player FSM cleaned** - states still contain some direct calculation; needs thinning
- [ ]  **Orchestration clean** - Player root should handle orchestration only

---

## Optional Non-Core Modules

### Projectile Base

- [x]  **Projectile entity** - runtime entity exists, separate from attack effect
- [x]  **Movement / collision cleanup** - handled in projectile lifecycle
- [x]  **ProjectileAttackEffect hookup** - wired
- [ ]  **Richer hit policy** - per-target hit dedup, pierce count, bounce if needed later

---

## Research

### World Generation

- [ ]  **Dungeon generation addons** - evaluate external addon vs current DungeonGenerator

### Damage Polish *(not required for demo)*

- [ ]  **Hitstop** - brief pause on heavy hits
- [ ]  **Advanced VFX manager** - see VFX Manager section above
- [ ]  **Damage number merging** - combine nearby numbers
- [ ]  **Damage number priority** - show most important number when too many
- [ ]  **Weapon system separation** - remove weapon fields from Stats into dedicated weapon resource