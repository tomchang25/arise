class_name WeaponExecutor
extends RefCounted
## Static factory — builds and wires all attack modules for one WeaponData.
## Returns a populated WeaponHandle. Holds no state of its own.
##
## Mirrors SpawnExecutor: pure inputs-in / handle-out, no identity.
##
## Called by CombatModule.setup(). Never instantiated directly.

static func build(weapon: WeaponData, host: Node, hitbox_slots: Array[Hitbox], stats: Stats) -> WeaponHandle:
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

        var module := _spawn_module(def, host, hitbox_slots, stats)
        handle.attack_modules.append(module)

    return handle

# -------------------------
# Internal
# -------------------------


static func _spawn_module(def: AttackDefinition, host: Node, slots: Array[Hitbox], stats: Stats) -> Object:
    if def is PlaceAttackDefinition:
        var m := PlaceAttackModule.new()
        m.setup(def, stats)
        host.add_child(m)
        return m

    if def is ProjectileAttackDefinition:
        var m := ProjectileAttackModule.new()
        m.setup(def, stats)
        host.add_child(m)
        return m

    if def is AttachedAttackDefinition:
        var m := AttachedAttackModule.new()
        var slot := _find_hitbox(slots, def.hitbox_slot_id, def)
        if slot != null:
            m.setup(def, stats, slot)
        host.add_child(m)
        return m

    push_error("WeaponExecutor: unrecognised AttackDefinition subclass: %s" % def.get_class())
    return null


static func _find_hitbox(slots: Array[Hitbox], hitbox_slot_id: StringName, def: AttackDefinition) -> Hitbox:
    if hitbox_slot_id == "":
        push_error(
            "WeaponExecutor: AttachedAttackDefinition has no hitbox_slot_id set (definition: '%s')" % def.resource_path,
        )
        return null

    for slot in slots:
        if slot.slot_id == hitbox_slot_id:
            return slot

    push_error(
        "WeaponExecutor: no Hitbox with slot_id '%s' found in hitbox_slots (definition: '%s')" %
        [hitbox_slot_id, def.resource_path],
    )
    return null
