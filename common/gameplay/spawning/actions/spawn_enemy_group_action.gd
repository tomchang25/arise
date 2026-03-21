class_name SpawnEnemyGroupAction
extends SpawnAction

# The group profile to spawn from.
var profile: EnemyGroupProfile


func execute(anchor: Node2D, ctx: SpawnContext) -> Node:
    if profile == null:
        Debug.warn("SpawnEnemyGroupAction: profile is null")
        return null

    if ctx == null or not is_instance_valid(ctx.spawn_parent):
        Debug.warn("SpawnEnemyGroupAction: ctx.spawn_parent is null or freed")
        return null

    if anchor == null:
        Debug.warn("SpawnEnemyGroupAction: anchor is null")
        return null

    var group := profile.group_scene.instantiate() as EnemyGroup
    if group == null:
        Debug.warn("SpawnEnemyGroupAction: group_scene did not instantiate to EnemyGroup")
        return null

    # Position before add_child so spawn_pivot captures correctly in EnemyGroup._ready()
    group.global_position = anchor.global_position
    ctx.spawn_parent.add_child(group)

    var rng := ctx.get_rng()
    var pairs := _resolve_member_counts(profile, rng)

    for pair in pairs:
        var scene: PackedScene = pair[0]
        var count: int = pair[1]

        for i in range(count):
            var enemy := scene.instantiate() as Enemy
            if enemy == null:
                Debug.warn("SpawnEnemyGroupAction: scene did not instantiate to Enemy")
                continue

            var offset := SpatialRandomUtils.random_point_in_circle(Vector2.ZERO, profile.spawn_radius, rng)
            enemy.home_position = group.spawn_pivot + offset
            group.add_child(enemy)
            group.register_member(enemy)

    return group

# -------------------------
# Internal
# -------------------------


# Returns Array of [PackedScene, int] pairs after rolling each entry and clamping to profile total.
func _resolve_member_counts(p: EnemyGroupProfile, rng: RandomNumberGenerator) -> Array:
    var pairs: Array = []
    var rolled_total := 0

    for entry in p.entries:
        if entry == null or not entry.is_valid():
            continue

        var min_c := mini(entry.min_count, entry.max_count)
        var max_c := maxi(entry.min_count, entry.max_count)
        var count := rng.randi_range(maxi(min_c, 0), maxi(max_c, 0))

        pairs.append([entry.scene, count])
        rolled_total += count

    if pairs.is_empty():
        return []

    var min_total := maxi(p.min_total, 1)
    var max_total := maxi(p.max_total, min_total)

    if rolled_total < min_total:
        Debug.warn("SpawnEnemyGroupAction: rolled_total %s < min_total %s — check profile entry ranges" % [rolled_total, min_total])

    # Trim excess from last entry first, then drop zeroed entries in one backwards pass.
    if rolled_total > max_total:
        var excess := rolled_total - max_total
        var i := pairs.size() - 1
        while i >= 0:
            if excess > 0:
                var trimmable: int = pairs[i][1]
                var trim := mini(trimmable, excess)
                pairs[i][1] -= trim
                excess -= trim
            if pairs[i][1] == 0:
                pairs.remove_at(i)
            i -= 1
    else:
        # No trimming needed — just drop any zero-count entries in one pass.
        for i in range(pairs.size() - 1, -1, -1):
            if pairs[i][1] == 0:
                pairs.remove_at(i)

    return pairs
