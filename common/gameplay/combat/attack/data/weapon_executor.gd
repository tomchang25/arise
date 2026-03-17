class_name WeaponExecutor
extends RefCounted

## Static factory — builds and wires all attack modules for one WeaponData.
## Returns a populated WeaponHandle. Holds no state of its own.
##
## Mirrors SpawnExecutor: pure inputs-in / handle-out, no identity.
##
## Called by CombatModule.setup(). Never instantiated directly.


static func build(weapon: WeaponData, host: Node, hitbox_slots: Array[Hitbox], next_slot: int) -> WeaponHandle:
    if weapon == null:
        push_warning("WeaponExecutor: null WeaponData — skipping")
        return null

    var handle := WeaponHandle.new()
    handle.weapon = weapon

    for i in weapon.attacks.size():
        var def := weapon.attacks[i] as AttackDefinition
        if def == null:
            push_warning("WeaponExecutor: null AttackDefinition at index %d in weapon '%s'" % [i, weapon.weapon_name])
            handle.attack_modules.append(null)
            continue

        var module := _spawn_module(def, host, hitbox_slots, next_slot)
        handle.attack_modules.append(module)

        if module is AttachedAttackModule:
            next_slot += 1

    return handle


# -------------------------
# Internal
# -------------------------


static func _spawn_module(def: AttackDefinition, host: Node, slots: Array[Hitbox], slot_index: int) -> Object:
    if def is PlaceAttackDefinition:
        var m := MeleeAttackModule.new()
        m.setup(def.cooldown)
        host.add_child(m)
        return m

    if def is ProjectileAttackDefinition:
        var m := ProjectileAttackModule.new()
        m.setup(def.cooldown, def.projectile_speed)
        host.add_child(m)
        return m

    if def is AttachedAttackDefinition:
        var m := AttachedAttackModule.new()
        if slot_index >= slots.size():
            push_error("WeaponExecutor: no hitbox slot available for Attached attack in weapon '%s'" % def.get_class())
        else:
            m.setup(slots[slot_index])
        host.add_child(m)
        return m

    push_error("WeaponExecutor: unrecognised AttackDefinition subclass: %s" % def.get_class())
    return null
