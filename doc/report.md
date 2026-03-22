# Frame-Time Gap Analysis — await Audit

**Scene:** `demo.tscn` — 300 `ninja_yellow` enemies, 10 `ninja_green` armies, 1 player
**Symptom:** Frame Time ~129 ms · Physics Time ~16 ms · Process Time ~21 ms → **~80 ms unaccounted**

---

## 1. All `await` Statements

| File | Function | Line | Code |
|------|----------|------|------|
| `common/framework/state_machine/state_machine.gd` | `_ready()` | 16 | `await target.ready` |
| `common/gameplay/combat/attack/effects/attack_effect.gd` | `play()` | 61 | `await get_tree().create_timer(duration).timeout` |
| `common/gameplay/combat/attack/effects/aoe_burst_effect.gd` | `play()` | 54 | `await get_tree().create_timer(duration).timeout` |
| `common/gameplay/combat/attack/effects/delivery_emitter.gd` | `play()` | 137 | `await get_tree().create_timer(duration).timeout` *(depth-guard branch)* |
| `common/gameplay/combat/attack/effects/delivery_emitter.gd` | `play()` | 146 | `await get_tree().create_timer(duration).timeout` *(single-shot branch)* |
| `common/gameplay/combat/attack/effects/delivery_emitter.gd` | `play()` | 152 | `await get_tree().create_timer(emit_interval).timeout` ⚠ **inside `while` loop** |
| `common/gameplay/combat/attack/effects/delivery_emitter.gd` | `_fire_and_setup()` | 255 | `var result: SpawnResult = await request.execute()` |
| `common/gameplay/combat/attack/effects/delivery_emitter.gd` | `_fire_and_setup()` | 266 | `await delivery.ready` |
| `common/gameplay/combat/attack/effects/phase_sequencer.gd` | `_run_next_phase()` | 95 | `await get_tree().create_timer(phase_def.lifetime).timeout` |
| `common/gameplay/combat/attack/effects/phase_sequencer.gd` | `_run_next_phase()` | 119 | `await effect.finished` |
| `common/gameplay/combat/attack/effects/projectile_attack_effect.gd` | `play()` | 30 | `await get_tree().create_timer(duration).timeout` |
| `common/gameplay/combat/attack/effects/scorch_effect.gd` | `play()` | 51 | `await _run_lifetime(duration)` |
| `common/gameplay/combat/attack/effects/scorch_effect.gd` | `_run_lifetime()` | 88 | `await get_tree().create_timer(active_time).timeout` |
| `common/gameplay/combat/attack/effects/scorch_effect.gd` | `_run_lifetime()` | 99 | `await tween.finished` |
| `common/gameplay/combat/attack/effects/slash_attack_effect.gd` | `_play_slash_vfx()` | 64 | `await tween.finished` |
| `common/gameplay/combat/attack/effects/telegraph_warning_effect.gd` | `play()` | 57 | `await _animate_warning(duration)` |
| `common/gameplay/combat/attack/effects/telegraph_warning_effect.gd` | `_animate_warning()` | 101 | `await get_tree().create_timer(pulse_duration).timeout` |
| `common/gameplay/combat/attack/effects/telegraph_warning_effect.gd` | `_animate_warning()` | 118 | `await flash_tween.finished` |
| `common/gameplay/combat/attack/effects/vfx_effect.gd` | `play()` | 25 | `await get_tree().create_timer(duration).timeout` |
| `common/gameplay/combat/attack/modules/place_attack_module.gd` | `_execute_attack_logic()` | 36 | `var result: SpawnResult = await request.execute()` |
| `common/gameplay/combat/attack/modules/place_attack_module.gd` | `_execute_attack_logic()` | 50 | `await delivery.ready` |
| `common/gameplay/combat/attack/modules/projectile_attack_module.gd` | `_execute_attack_logic()` | 36 | `var result: SpawnResult = await request.execute()` |
| `common/gameplay/combat/attack/modules/projectile_attack_module.gd` | `_execute_attack_logic()` | 49 | `await delivery.ready` |
| `common/gameplay/combat/environment/environment_spawner.gd` | `fire()` | 53 | `return await fire_def(attack_defs[index], world_position)` |
| `common/gameplay/combat/environment/environment_spawner.gd` | `fire_def()` | 68 | `return await _spawn(def, world_position)` |
| `common/gameplay/combat/environment/environment_spawner.gd` | `_spawn()` | 108 | `var result: SpawnResult = await request.execute()` |
| `common/gameplay/combat/environment/environment_spawner.gd` | `_spawn()` | 119 | `await delivery.ready` |
| `common/gameplay/combat/damage_response/damage_number_module.gd` | `spawn_damage_number()` | 78 | `var result := await request.execute()` |
| `common/gameplay/spawning/points/warning_spawn_point.gd` | `start()` | 33 | `await _play_warning()` |
| `common/gameplay/spawning/points/warning_spawn_point.gd` | `_play_warning()` | 48 | `await _warning_timer.timeout` |
| `common/gameplay/spawning/request/spawn_request.gd` | `execute()` | 48 | `spawned_node = await SpawnWarningExecutor.execute_at_position(...)` |
| `common/gameplay/spawning/runtime/spawn_warning_executor.gd` | `execute_at_position()` | 27 | `return await point.start()` |
| `common/gameplay/encounter/encounter_controller.gd` | `_spawn_group()` | 287 | `var spawned := await SpawnWarningExecutor.execute_at_position(...)` |
| `game/actors/states/actor_state.gd` | `_ready()` | 20 | `await owner.ready` |
| `game/actors/player/state/player_state.gd` | `_ready()` | 21 | `await owner.ready` |
| `game/actors/dummies/dummy.gd` | `_on_died()` | 185 | `var result: SpawnResult = await request.execute()` |
| `game/actors/dummies/dummy.gd` | `_on_died()` | 190 | `await delivery.ready` |
| `stage/testbeds/phase_effect_preview/phase_effect_preview.gd` | `_on_effect_finished()` | 113 | `await get_tree().create_timer(loop_delay).timeout` |
| `stage/testbeds/encounter_testbed/encounter_testbed.gd` | *(testbed loop)* | 169 | `await get_tree().create_timer(1.0).timeout` |
| `stage/testbeds/spawn_system_testbed/spawn_system_testbed.gd` | *(testbed helper)* | 123 | `var spawned := await _spawn_from_runtime_warning_point(...)` |
| `stage/testbeds/spawn_system_testbed/spawn_system_testbed.gd` | *(testbed helper)* | 279 | `return await SpawnWarningExecutor.execute_at_position(...)` |
| `stage/testbeds/spawn_system_testbed/spawn_system_testbed.gd` | *(testbed helper)* | 290 | `return await runtime_point.start()` |

---

## 2. Root-Cause Analysis

### Most Likely Culprit: `delivery_emitter.gd` — `await` inside a `while` loop

**File:** `common/gameplay/combat/attack/effects/delivery_emitter.gd`
**Function:** `play()` · **Line 148–156**

```gdscript
# BEFORE — creates a brand-new SceneTreeTimer object on every iteration
var elapsed := 0.0
while elapsed + emit_interval < duration:
    await get_tree().create_timer(emit_interval).timeout   # ← allocation per tick
    elapsed += emit_interval
    if not is_inside_tree():
        break
    _emit_burst(resolved_def)
```

#### Why this causes the 80 ms gap

| Factor | Detail |
|--------|--------|
| **Per-iteration GC allocation** | Each `get_tree().create_timer()` call heap-allocates a new `SceneTreeTimer` RefCounted object. With 300 enemies potentially mid-attack, dozens of concurrent emitter coroutines each spin this loop, creating hundreds of short-lived objects per second. The GC flush and reference-counting overhead accumulate silently. |
| **Coroutine state overhead** | Each `await` suspends and resumes a GDScript coroutine. Hundreds of live coroutines (one per active emitter interval) means hundreds of resume/suspend round-trips per second, each costing script interpreter time that does **not** appear under Process Time or Physics Time in the profiler. |
| **SceneTree timer iteration** | Every frame the SceneTree walks its internal timer list to tick all active `SceneTreeTimer`s. With hundreds of concurrent timers from emitter loops plus attack-effect lifetimes, this walk grows O(N) and the cost hides in engine overhead rather than script time. |
| **Fits the gap profile** | Physics (16 ms) + Process (21 ms) = 37 ms accounted. The ~80 ms remainder matches engine overhead — timer GC, coroutine scheduling, and SceneTree internal work — not user-script work that would show up in the profiler counters. |

#### Secondary contributors (lower priority, not fixed here)

- `attack_effect.gd`, `vfx_effect.gd`, `aoe_burst_effect.gd`, `projectile_attack_effect.gd` — each call `create_timer` once per active effect. With 300 enemies, many instances run simultaneously, compounding the SceneTree timer-list size.
- `encounter_controller._spawn_group()` — called without `await` from `_process`, so the frame does not block; however, the synchronous prelude (scene instantiation, `add_child`) runs inline before the first suspension.

---

## 3. Fix Applied

**Strategy:** Replace the `while`-loop `create_timer` with delta accumulation in `_process`.

- `play()` fires the first burst synchronously, stores the resolved definition and remaining lifetime in instance variables, and returns immediately (no coroutine suspended).
- `_process(delta)` decrements the lifetime and the interval accumulator every frame with a plain float subtraction — zero allocations, zero coroutine overhead.
- `finished` is emitted from `_process` when the lifetime expires, preserving the `PhaseSequencer` contract (`await effect.finished`).

**File changed:** `common/gameplay/combat/attack/effects/delivery_emitter.gd`

See the diff for exact changes. Single-shot (`emit_interval <= 0`) and depth-guard branches are unchanged; only the repeating loop is affected.
