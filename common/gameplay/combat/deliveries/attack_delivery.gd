class_name AttackDelivery
extends CharacterBody2D

## Base class for all spawned, fire-and-forget attack instances.
##
## Responsibilities:
##   1. Lifetime — self-destructs when attack_lifetime expires.
##   2. Origin source — holds the spawner node for future AttackData rebuilds.
##   3. Effect instantiation — spawns the AttackEffect from data.attack_effect_scene,
##      adds it as a child, then calls play(lifetime) on it.
##
## The delivery scene itself contains no AttackEffect child in the editor.
## The effect is always injected at runtime from AttackData, so any delivery
## scene can be paired with any effect scene via the AttackDefinition.

# -------------------------
# Runtime state
# -------------------------

## The node that spawned this delivery — typically the actor's CombatModule.
## Retained for future AttackData rebuilding (e.g. live knockback source).
var origin_source: Node2D = null

var _attack_effect: AttackEffect
var _lifetime_timer: float = 0.0

# -------------------------
# Lifecycle
# -------------------------


func setup(data: AttackData, source: Node2D = null) -> void:
    origin_source = source
    _lifetime_timer = data.attack_lifetime

    if data.attack_effect_scene != null:
        _attack_effect = data.attack_effect_scene.instantiate() as AttackEffect
        if _attack_effect == null:
            push_error("AttackDelivery: attack_effect_scene does not instantiate to AttackEffect in '%s'" % name)
        else:
            add_child(_attack_effect)
            _attack_effect.setup(data)
            _attack_effect.play(data.attack_lifetime)
    else:
        push_warning("AttackDelivery: no attack_effect_scene in AttackData for '%s'" % name)


func _process(delta: float) -> void:
    _lifetime_timer -= delta
    if _lifetime_timer <= 0.0:
        queue_free()
