class_name AttackData
extends RefCounted

enum DeliveryType { PLACE, PROJECTILE, ATTACHED }

## The scene to instantiate for fire-and-forget delivery types (Place, Projectile).
## Not used by Attached — those manage their own hitbox node.
var attack_scene: PackedScene = null

## Base damage before variance: stats.current_damage * damage_multiplier
var base_damage: float = 0.0

## Variance roll added on top of base: positive or negative offset
var rolled_damage: float = 0.0

## Whether this hit is a critical strike
var is_crit: bool = false

## Crit multiplier applied when is_crit is true. Set by CombatModule from stats.
var crit_multiplier: float = 1.5

## Final damage dealt: (base_damage + rolled_damage) * crit_multiplier if is_crit.
## This is what DamageReceiverModule reads.
var final_damage: float:
    get:
        var dmg := base_damage + rolled_damage
        if is_crit:
            dmg *= crit_multiplier
        return dmg

var max_targets: int = -1
var attack_lifetime: float = 0.2
var target_factions: Array = []

## Pre-baked travel/facing direction of the attack.
## Set for fire-and-forget types (Place, Projectile).
## HitFeedbackModule uses this when knockback_source is null.
var knockback_dir: Vector2 = Vector2.ZERO

## Live node reference to the attack origin.
## Set for Attached attacks so victims compute knockback direction
## as (victim → knockback_source) at hit time.
## Takes priority over knockback_dir in HitFeedbackModule.
var knockback_source: Node2D = null
var knockback_force: float = 0.0

## Delivery type resolved from the definition class at build time.
## PLACE / PROJECTILE → fire-and-forget, knockback_dir is baked.
## ATTACHED           → persistent, knockback_source is a live node.
var delivery_type: int = DeliveryType.PLACE

var travel_distance: float = 0.0


func apply_knockback_source(source: Node2D, target_pos: Vector2) -> void:
    match delivery_type:
        DeliveryType.ATTACHED:
            # Victim resolves direction at hit time: (victim → source).
            knockback_source = source

        DeliveryType.PLACE, DeliveryType.PROJECTILE:
            # Bake direction now — source position is reliable at spawn time.
            var dir := target_pos - source.global_position
            knockback_dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.RIGHT

        _:
            push_warning("AttackData: unknown delivery_type %d, knockback dir not set" % delivery_type)
