class_name EffectPhaseDefinition
extends Resource
## Defines one phase in a multi-phase attack.
##
## A phase is the smallest independently timed unit of an attack delivery.
## Multiple phases are chained together inside an AttackDelivery via PhaseSequencer
## (Step 2 of the combat improvement plan).
##
## Damage / hit fields here override the parent AttackDefinition's values for this
## phase only. Set a field to its sentinel (see below) to inherit from the parent.
##
## Authoring guide
## ───────────────
## Single-phase attack (slash, ground slam):
##   phases = [ one EffectPhaseDefinition with effect_scene = slash_effect.tscn ]
##
## RPG explosion chain:
##   phases[0]  large AOE burst   → effect_scene = aoe_effect.tscn,   lifetime = 0.2
##   phases[1]  burn DoT          → effect_scene = burn_effect.tscn,  lifetime = 10.0
##   phases[2]  scorch mark VFX   → effect_scene = null,              lifetime = 30.0
##
## VFX-only phase:
##   Set effect_scene = null. PhaseSequencer will wait the lifetime duration and
##   then advance without spawning any AttackEffect or Hitbox.

@export_group("Scene")

## The AttackEffect scene to instantiate for this phase.
##
## Null = VFX-only phase.  The PhaseSequencer waits `lifetime` seconds and advances
## without spawning any effect or damage hitbox.  Use this for lingering decals,
## scorch marks, or environmental VFX that should not deal damage.
@export var effect_scene: PackedScene = null

@export_group("Timing")

## How long this phase is active before the next phase begins (or the delivery frees).
## Must be > 0.
@export var lifetime: float = 0.2

@export_group("Hit Overrides")
## Per-phase damage interval override.
## Seconds between repeated hits on the same victim while inside this phase's Hitbox.
## Set to -1.0 to inherit from the parent AttackDefinition.
@export var damage_interval: float = -1.0

## Per-phase max-targets override.
## Set to -1 to inherit from the parent AttackDefinition.
@export var max_targets: int = -1

## Per-phase clear_records_on_exit override.
## When true, a victim who exits and re-enters the hitbox can be hit again.
## Matches AttackDefinition.clear_records_on_exit semantics.
## Set to -1 to inherit from the parent AttackDefinition.
##
## -1 = inherit  |  0 = false  |  1 = true
@export_range(-1, 1, 1) var clear_records_on_exit_override: int = -1
