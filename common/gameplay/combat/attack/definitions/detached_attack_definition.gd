class_name DetachedAttackDefinition
extends AttackDefinition
## Base for detached (fire-and-forget) delivery types (Place and Projectile).
## Do not instantiate this directly — use PlaceAttackDefinition
## or ProjectileAttackDefinition.
##
## Step 2 addition: phases array
## ─────────────────────────────
## Fill `phases` to use the new PhaseSequencer path in AttackDelivery.
## Leave it empty and set `attack_effect_scene` to keep the legacy single-effect path.
##
## The two paths are mutually exclusive at runtime:
##   phases non-empty  → PhaseSequencer drives the effect chain.
##   phases empty      → AttackDelivery falls back to attack_effect_scene (legacy).
##
## Do NOT fill both — attack_effect_scene is ignored when phases is non-empty.

@export_group("Spawn")

## The delivery scene to instantiate when the attack fires.
## Root node must extend AttackDelivery.
## Controls how the attack moves and how long it lives.
@export var attack_scene: PackedScene = null

## [New] Ordered array of effect phases for this attack.
## Non-empty activates the PhaseSequencer path in AttackDelivery.trigger().
## Each entry is an EffectPhaseDefinition describing one timed effect stage.
##
## Example — RPG:
##   phases[0]  AOE burst        (effect_scene = aoe_effect.tscn, lifetime = 0.2)
##   phases[1]  burn DoT         (effect_scene = burn_effect.tscn, lifetime = 10.0)
##   phases[2]  scorch VFX only  (effect_scene = null, lifetime = 30.0)
@export var phases: Array[EffectPhaseDefinition] = []

@export_group("Attack Range")

## Maximum distance from the actor the attack can be placed.
@export var attack_range: float = 40.0

@export_group("Cooldown")
@export var cooldown: float = 0.5
