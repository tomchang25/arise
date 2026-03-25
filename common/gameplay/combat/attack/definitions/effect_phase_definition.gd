class_name EffectPhaseDefinition
extends Resource
## Defines one phase in a multi-phase attack.
##
## A phase is the smallest independently timed unit of an attack delivery.
## Multiple phases are chained together inside an AttackDelivery via PhaseSequencer.
##
## Each phase is fully authoritative over its own hit config — there is no sentinel
## / inherit system. Every field must be set explicitly. This makes phase behaviour
## unambiguous and keeps build_phase_override() free of conditional logic.
##
## Authoring guide
## ───────────────
## Single-phase attack (slash, ground slam):
##   phases = [ one EffectPhaseDefinition with effect_scene = slash_effect.tscn ]
##
## RPG explosion chain:
##   phases[0]  AOE burst  → effect_scene = aoe_effect.tscn,  lifetime = 0.2,
##                           knockback_mode = OUTWARD, knockback_force = 200.0
##   phases[1]  burn DoT   → effect_scene = burn_effect.tscn, lifetime = 5.0,
##                           knockback_mode = INWARD,  knockback_force = 80.0
##   phases[2]  scorch VFX → effect_scene = null, lifetime = 10.0
##
## VFX-only phase:
##   Set effect_scene = null. PhaseSequencer will wait the lifetime duration and
##   then advance without spawning any AttackEffect or Hitbox.

## Controls how knockback direction is computed for victims hit in this phase.
##
## FIXED   — use knockback_dir as baked at spawn time (travel direction of the
##           projectile / facing direction of the caster). Default behaviour.
##           Good for: melee slashes, linear projectiles.
##
## OUTWARD — push victims away from the AttackEffect's world position at hit time.
##           Good for: explosions, shockwaves.
##
## INWARD  — pull victims toward the AttackEffect's world position at hit time.
##           Good for: implosions, vortex/suck effects, burn DoT pulling to center.
enum KnockbackMode {
    FIXED,
    OUTWARD,
    INWARD,
}

@export_group("Scene")
## The AttackEffect scene to instantiate for this phase.
##
## Null = VFX-only phase. The PhaseSequencer waits `lifetime` seconds and advances
## without spawning any effect or damage hitbox. Use this for lingering decals,
## scorch marks, or environmental VFX that should not deal damage.
@export var effect_scene: PackedScene = null

@export_group("Timing")
## How long this phase is active before the next phase begins (or the delivery frees).
## Must be > 0.
@export var lifetime: float = 0.2

@export_group("Hit")
## How knockback direction is determined for this phase. See KnockbackMode.
@export var knockback_mode: KnockbackMode = KnockbackMode.FIXED

## Knockback force applied to victims hit during this phase.
@export var knockback_force: float = 0.0

## Maximum number of victims this phase's hitbox can hit before disabling itself.
## -1 = unlimited.
@export var max_targets: int = 1

## Seconds between repeated hits on the same victim while inside this phase's hitbox.
## 0 = hit on enter only, never repeat while inside.
@export var damage_interval: float = 0.0

## If true, the victim's hit record is cleared when they exit this phase's hitbox —
## re-entering will trigger a hit again.
## If false, a victim hit once is immune for the entire phase lifetime.
@export var clear_records_on_exit: bool = false

@export_group("Lifetime")
## If true, PhaseSequencer cancels remaining phases when the attacker is freed.
@export var quit_on_source_invalid: bool = false
