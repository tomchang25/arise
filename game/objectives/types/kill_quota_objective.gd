class_name KillQuotaObjective
extends Objective

# -------------------------
# Configuration
# -------------------------

@export var target_count: int = 10

# -------------------------
# State
# -------------------------

var current_count: int = 0

# -------------------------
# Common API
# -------------------------


func get_objective_text() -> String:
    return "Kill enemies: %d / %d" % [current_count, target_count]


# -------------------------
# Event Handling
# -------------------------


func on_event(event_name: StringName, _payload: Variant = null) -> void:
    if not active:
        return

    if event_name == &"enemy_killed":
        _on_enemy_killed()


# -------------------------
# Internal
# -------------------------


func _on_enemy_killed() -> void:
    current_count += 1
    if current_count >= target_count:
        _complete()
