class_name CombatModule
extends Node2D

@export var stats: Stats
@export var melee_attack: MeleeAttackModule
@export var projectile_attack: ProjectileAttackModule


func _ready() -> void:
    if not melee_attack:
        melee_attack = find_child("MeleeAttackModule", true, false)

    if not melee_attack:
        melee_attack = MeleeAttackModule.new()
        add_child(melee_attack)

    if not projectile_attack:
        projectile_attack = find_child("ProjectileAttackModule", true, false)

    if not projectile_attack:
        projectile_attack = ProjectileAttackModule.new()
        add_child(projectile_attack)


func perform_attack(slot: Stats.AttackSlot, target_position: Vector2) -> void:
    if stats == null:
        push_error("CombatModule: stats is not set")
        return

    var attack_range := get_attack_range(slot)
    if attack_range <= 0.0:
        return

    var origin := global_position
    var distance := origin.distance_to(target_position)

    if distance > attack_range + 0.01:
        push_warning("CombatModule: target out of range. (%s > %s)" % [distance, attack_range])
        return

    var info := _build_attack_info(slot, target_position)
    if info == null:
        return

    var executor := _get_executor_for(info.delivery_type)
    if executor == null:
        push_error("CombatModule: no executor for delivery_type %s" % info.delivery_type)
        return

    if not executor.can_attack():
        return

    executor.execute_attack(target_position, info)
    executor.end_attack()


func get_attack_range(slot: Stats.AttackSlot) -> float:
    if stats == null:
        return 0.0

    match slot:
        Stats.AttackSlot.PRIMARY:
            return stats.primary_attack_range
        Stats.AttackSlot.SECONDARY:
            return stats.secondary_attack_range
        _:
            return 0.0


func get_attack_origin() -> Vector2:
    return global_position


func _get_executor_for(delivery_type: int) -> AttackModule:
    match delivery_type:
        AttackInfo.DeliveryType.MELEE:
            return melee_attack
        AttackInfo.DeliveryType.PROJECTILE:
            return projectile_attack
        _:
            return null


func _build_attack_info(slot: Stats.AttackSlot, target_position: Vector2) -> AttackInfo:
    var info := AttackInfo.new()
    info.slot = slot
    info.source_position = global_position
    info.target_factions = _build_target_factions()

    var damage_multiplier := 1.0
    var damage_variance := 0.0
    var crit_bonus := 0.0
    var effect_scene: PackedScene = null

    match slot:
        Stats.AttackSlot.PRIMARY:
            info.delivery_type = stats.primary_delivery_type
            effect_scene = stats.primary_effect_scene
            damage_multiplier = stats.primary_damage_multiplier
            damage_variance = stats.primary_damage_variance
            crit_bonus = stats.primary_crit_bonus
            info.knockback_force = stats.primary_knockback
            info.attack_lifetime = stats.primary_lifetime
            info.max_targets = stats.primary_max_targets

        Stats.AttackSlot.SECONDARY:
            info.delivery_type = stats.secondary_delivery_type
            effect_scene = stats.secondary_effect_scene
            damage_multiplier = stats.secondary_damage_multiplier
            damage_variance = stats.secondary_damage_variance
            crit_bonus = stats.secondary_crit_bonus
            info.knockback_force = stats.secondary_knockback
            info.attack_lifetime = stats.secondary_lifetime
            info.max_targets = stats.secondary_max_targets

        _:
            push_warning("CombatModule: unsupported attack slot %s" % slot)
            return null

    if effect_scene == null:
        push_warning("CombatModule: no effect_scene set for slot %s" % slot)
        return null

    info.effect_scene = effect_scene
    info.base_damage = stats.current_damage * damage_multiplier
    info.rolled_damage = _roll_damage(info.base_damage, damage_variance)
    info.is_crit = _roll_crit(stats.current_crit_chance + crit_bonus)
    info.final_damage = info.rolled_damage

    if info.is_crit:
        info.final_damage *= stats.current_crit_multiplier

    var dir := target_position - global_position
    if dir.length_squared() <= 0.0001:
        dir = Vector2.RIGHT
    else:
        dir = dir.normalized()

    info.knockback_dir = dir

    return info


func _build_target_factions() -> Array:
    match stats.faction:
        Stats.Faction.PLAYER:
            return [Stats.Faction.ENEMY, Stats.Faction.NEUTRAL]
        Stats.Faction.ENEMY:
            return [Stats.Faction.PLAYER]
        Stats.Faction.NEUTRAL:
            return []
        _:
            return []


func _roll_damage(base_damage: float, variance: float) -> float:
    variance = max(variance, 0.0)
    if variance <= 0.0:
        return base_damage

    var min_mul := 1.0 - variance
    var max_mul := 1.0 + variance
    return base_damage * randf_range(min_mul, max_mul)


func _roll_crit(chance: float) -> bool:
    chance = clamp(chance, 0.0, 1.0)
    return randf() < chance
