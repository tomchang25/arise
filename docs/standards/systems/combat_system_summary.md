# Combat System

Location  
`common/gameplay/combat/`

Purpose  
Handles all actor-to-actor damage in Arise.  
The system separates attack configuration (`AttackDefinition` subclasses, `WeaponData`) from runtime data (`AttackData`) and execution (`AttackModule` subclasses, `AttackDelivery`, `AttackEffect`).  
It supports three delivery types — **Place** (stationary hitbox at a world position), **Projectile** (moving hitbox launched from the caster), and **Attached** (persistent hitbox living on the actor itself) — all unified under a single `CombatModule` API.  
Hit detection uses a `Hitbox` / `Hurtbox` Area2D pair; damage routing and knockback are handled by the victim's own feedback systems.

Core Components

`CombatModule`  
Node added to any actor that can deal damage. Holds `WeaponData` resources and `Hitbox` slot references. Builds and owns all `WeaponHandle` instances. Exposes the public attack API to external callers (states, AI, player input).

`WeaponData`  
Resource describing one weapon. Contains an ordered array of `AttackDefinition` resources. Index 0 = primary, index 1 = secondary; further entries are extra attacks.

`AttackDefinition`  
Base resource carrying fields shared by all delivery types: `damage_multiplier`, `damage_variance`, `crit_bonus`, `knockback`, `max_targets`, `damage_interval`, `clear_records_on_exit`, and `faction_target_type`.

`DetachedAttackDefinition`  
Intermediate base for fire-and-forget types. Adds `attack_scene` (the delivery), `attack_effect_scene` (the effect), and `cooldown`.

`PlaceAttackDefinition`  
Spawns a stationary `AttackDelivery` at the target position. Adds `attack_range` and `lifetime`.

`ProjectileAttackDefinition`  
Spawns a moving `AttackDelivery` from the caster. Adds `travel_distance`, `lifetime`, and `projectile_speed`.

`AttachedAttackDefinition`  
Binds to a pre-authored `Hitbox` node in the actor scene via `hitbox_slot_id`. No delivery scene — the hitbox is toggled on/off directly.

`AttackData`  
Runtime-only data object built from a definition + caster context. Holds baked damage values, `final_damage` (rolled fresh per read with variance + crit), `knockback_dir` (pre-baked for detached types) or `knockback_source` (live reference for Attached), and hitbox configuration. Never serialised.

`WeaponHandle`  
Runtime container for one equipped weapon. Holds the live `AttackModule` array, index-matched to `weapon.attacks`. Owns enabled state and teardown logic.

`WeaponExecutor`  
Static factory that builds a `WeaponHandle` from a `WeaponData`. Instantiates the correct `AttackModule` subclass for each definition and adds it as a child of the host actor. No state of its own.

`AttackModule`  
Abstract base for all execution units. Provides `enabled`, `can_attack()`, and stub implementations of `execute_attack`, `end_attack`, `activate_attack`, `deactivate_attack`.

`DetachedAttackModule`  
Base for Place and Projectile executors. Owns the cooldown `Timer` and `locked` flag. Delegates to `_execute_attack_logic()` in subclasses.

`PlaceAttackModule`  
Spawns the delivery scene at the target world position via `SpawnRequest`. Calls `delivery.setup(data, self)` after spawn and sets `delivery.rotation` from `knockback_dir`.

`ProjectileAttackModule`  
Spawns the delivery at the caster's position, then calls `delivery.launch(dir, speed)` to start motion.

`AttachedAttackModule`  
Wraps the pre-authored `Hitbox` injected by `CombatModule`. `activate_attack()` enables the hitbox with the given data; `deactivate_attack()` disables it.

`AttackDelivery`  
Base scene node (`CharacterBody2D`) for spawned, fire-and-forget attack instances. Owns the lifetime countdown timer and `origin_source` reference. Instantiates `AttackEffect` from `data.attack_effect_scene`, adds it as a child, and calls `effect.play(lifetime)`.

`ProjectileAttackDelivery`  
Extends `AttackDelivery` with straight-line motion via `move_and_collide`. Stops and despawns on wall collision.

`AttackEffect`  
Base node for visuals, SFX, and hitbox hosting. Finds its `Hitbox` child, wires it with `AttackData`, and exposes `play(duration)` for subclass VFX. Never calls `queue_free` — lifetime is owned by the delivery.

`SlashAttackEffect`  
Draws an animated arc `Line2D` and generates a `CapsuleShape2D` for the hitbox.

`ProjectileAttackEffect`  
Draws a comet `Line2D` and generates a `CircleShape2D` for the hitbox.

`Hitbox`  
`Area2D` on the attacker side. Carries `AttackData`, `damage_interval`, and `clear_records_on_exit`. Emits `hit_enemy` when a valid `Hurtbox` enters. Re-hits victims on an interval while they remain inside if `damage_interval > 0`.

`Hurtbox`  
`Area2D` on the victim side. Collision layers are set from the owner's `Stats.faction`. Emits `get_hit(attack_info)` when `receive_hit()` is called by the `Hitbox`.

System Flow

### Place attack

`CombatModule.perform_attack(wi, ai, target_pos)`  
→ `AttackData.build(def, stats, source, target_pos)`  
→ `PlaceAttackModule.execute_attack(target_pos, data)`  
→ `SpawnRequest.setup_direct()` → `SpawnResult`  
→ `AttackDelivery.setup(data, source)`  
→ `AttackEffect.setup(data)` → `AttackEffect.play(lifetime)`  
→ `Hitbox` active → hits `Hurtbox` → `get_hit` signal  
→ lifetime expires → `AttackDelivery.queue_free()`

### Projectile attack

`CombatModule.perform_attack(wi, ai, target_pos)`  
→ `AttackData.build(def, stats, source, target_pos)`  
→ `ProjectileAttackModule.execute_attack(target_pos, data)`  
→ `SpawnRequest` at caster position → `SpawnResult`  
→ `AttackDelivery.setup(data, source)`  
→ `ProjectileAttackDelivery.launch(dir, speed)`  
→ motion via `move_and_collide` each physics frame  
→ wall collision or lifetime expiry → `queue_free()`

### Attached attack

`CombatModule.activate_attack(wi, ai)`  
→ `AttackData.build(def, stats, source)` (no target_pos)  
→ `AttachedAttackModule.activate_attack(data)`  
→ `Hitbox.enabled = true` → continuous hit detection  
`CombatModule.deactivate_attack(wi, ai)`  
→ `AttachedAttackModule.deactivate_attack()`  
→ `Hitbox.enabled = false`

Main API

`CombatModule.perform_attack(weapon_index, attack_index, target_position, auto_end)`  
Fire a detached (Place or Projectile) attack.

`CombatModule.end_attack(weapon_index, attack_index)`  
Start the cooldown timer, unlocking the module.

`CombatModule.can_attack(weapon_index, attack_index) -> bool`  
Returns true if the module is enabled and not locked.

`CombatModule.activate_attack(weapon_index, attack_index)`  
Enable the hitbox for an Attached attack.

`CombatModule.deactivate_attack(weapon_index, attack_index)`  
Disable the hitbox for an Attached attack.

`CombatModule.set_weapon_enabled(weapon_index, enabled)`  
Enable or disable an entire weapon and all its modules.

`CombatModule.get_attack_range(weapon_index, attack_index) -> float`  
Returns the effective range (only meaningful for Place attacks).

`CombatModule.set_attack_range_override(weapon_index, attack_index, value)`  
Override range at runtime without mutating resources (buffs, god mode).

`CombatModule.clear_attack_range_override(weapon_index, attack_index)`  
Restore a single weapon/attack to its definition base range.

`CombatModule.clear_all_range_overrides()`  
Restore all weapons to their definition base ranges.

`AttackData.build(def, stats, source, target_position) -> AttackData`  
Factory. Pass `target_position` for Place/Projectile to bake `knockback_dir`; omit for Attached (stores `knockback_source` instead).

`AttackDelivery.setup(data, source)`  
Inject runtime data, start the lifetime timer, and instantiate the effect.

`AttackEffect.play(duration)`  
Override in subclasses to run VFX and SFX scaled to the delivery lifetime.

`Hitbox.enabled`  
Toggle hit detection on/off. Cleared hit records when disabled.

`Hurtbox.receive_hit(attack_info)`  
Entry point for the victim; emits `get_hit` signal.

Typical Usage

### Place attack from an enemy AI state

```gdscript
if combat_module.can_attack(0, 0):
    combat_module.perform_attack(0, 0, player.global_position, true)
```

### Projectile attack

```gdscript
if combat_module.can_attack(0, 1):
    combat_module.perform_attack(0, 1, target_position)
    await animation_player.animation_finished
    combat_module.end_attack(0, 1)
```

### Attached hitbox toggled by animation

```gdscript
# Triggered by animation track event:
func _on_attack_start() -> void:
    combat_module.activate_attack(0, 0)

func _on_attack_end() -> void:
    combat_module.deactivate_attack(0, 0)
```

### Temporary range buff

```gdscript
combat_module.set_attack_range_override(0, 0, base_range * 1.5)
await buff_timer.timeout
combat_module.clear_attack_range_override(0, 0)
```

### Building AttackData manually (e.g. for a TrapDelivery)

```gdscript
var data := AttackData.build(trap_definition, owner_stats, self, Vector2.ZERO)
delivery.setup(data, self)
```

Design Rules

- The combat system separates **configuration** (definition resources, `WeaponData`) from **runtime state** (`AttackData`, `WeaponHandle`, module instances) — definitions are never mutated at runtime.
- `AttackData.final_damage` is a computed property that rolls variance and crit fresh each read, so multi-target hits and interval ticks each get an independent result.
- `AttackDelivery` owns lifetime; `AttackEffect` owns visuals and the hitbox. An effect never calls `queue_free` directly.
- Delivery type is determined by the `AttackDefinition` subclass; `WeaponExecutor` maps it to the correct module without any caller-side type checks.
- `AttackData.knockback_dir` is pre-baked at spawn time for detached attacks; Attached attacks store `knockback_source` so victims compute direction at hit time.
- `Hitbox.slot_id` binds Attached definitions to pre-authored scene nodes by name — order of `hitbox_slots` in the inspector is irrelevant.
- Range overrides go through `CombatModule` and never write back to definition resources.
- `WeaponHandle.teardown()` handles both hitbox deactivation and module `queue_free`, so `CombatModule` only needs to call one method on teardown.

Notes

- `AttackData.final_damage` rolls variance on every read — do not store it in a local variable if independent results per tick are needed.
- `PlaceAttackModule` sets `delivery.rotation` from `knockback_dir` before calling `setup()`, so the delivery scene can use `transform.x` as a facing direction for VFX.
- `ProjectileAttackDelivery` sets its own rotation from `launch(dir, speed)` — callers should not set rotation separately.
- `AttackEffect` sub-classes generate their `Hitbox` collision shape at runtime in `setup()` if none is pre-authored, so shape fields may be set via exports rather than the scene tree.
- `Hitbox.damage_interval = 0` means hit-on-enter only; the victim is immune for the hitbox lifetime unless `clear_records_on_exit = true` and they physically leave and re-enter.
- `FactionTargetType.ALL` on a definition allows self-damage and ally damage — required for trap-style attacks that should hit any faction.
- Detached modules hold a `locked` flag (not a timer) during execution; `end_attack()` starts the cooldown timer which clears `locked` on timeout.
- `CombatModule.deactivate_attack()` bypasses the handle `enabled` guard — teardown must always be permitted.
