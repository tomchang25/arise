class_name KillBossObjective
extends Objective

# -------------------------
# State
# -------------------------

var _bosses: Array[Node] = []
var _alive_count: int = 0

# -------------------------
# Common API
# -------------------------


func get_objective_text() -> String:
    if _alive_count <= 1:
        return "Defeat the boss"
    return "Defeat all bosses: %d remaining" % _alive_count


## Call this before registering with ObjectiveManager.
## Pass all boss nodes that must be killed to complete the objective.
func register_bosses(bosses: Array[Node]) -> void:
    _bosses.clear()
    _alive_count = 0

    for boss in bosses:
        if boss == null:
            continue

        _bosses.append(boss)
        _alive_count += 1

        # Connect to tree_exiting so we catch queue_free() reliably
        if not boss.tree_exiting.is_connected(_on_boss_exiting_tree):
            boss.tree_exiting.connect(_on_boss_exiting_tree.bind(boss))


# -------------------------
# Signals / Callbacks
# -------------------------


func _on_boss_exiting_tree(_boss: Node) -> void:
    if not active:
        return

    _alive_count = max(0, _alive_count - 1)

    if _alive_count <= 0:
        _complete()
