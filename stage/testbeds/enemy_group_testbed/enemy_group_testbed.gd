extends Node2D

# -------------------------
# Hotkeys
# -------------------------

const ACTION_RESET_PLAYER  := "test_reset_player"
const ACTION_RESET_ENEMIES := "test_reset_enemies"
const ACTION_KILL_ALL      := "test_kill_all_enemies"

# -------------------------
# Exports
# -------------------------

@export_group("Scene References")
@export var player: Player
@export var player_spawn: Marker2D
@export var enemies_root: Node2D

@export_group("Group Spawns")
@export var enemy_scene: PackedScene
@export var group_spawn_markers: Array[Marker2D]  ## One Marker2D per group — place 3 in the scene
@export var enemies_per_group: int = 3
@export var spawn_scatter_radius: float = 40.0

@export_group("Debug")
@export var debug_label: Label
@export var print_hotkey_log := true

# -------------------------
# Internal
# -------------------------

var _groups: Array[EnemyGroup] = []


# -------------------------
# Lifecycle
# -------------------------

func _ready() -> void:
    _ensure_test_actions()
    _apply_start_positions()
    _spawn_all_groups()
    _update_debug_label()


func _process(_delta: float) -> void:
    _update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed(ACTION_RESET_PLAYER):
        _on_reset_player()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_RESET_ENEMIES):
        _on_reset_enemies()
        get_viewport().set_input_as_handled()
        return

    if event.is_action_pressed(ACTION_KILL_ALL):
        _on_kill_all()
        get_viewport().set_input_as_handled()
        return


# -------------------------
# Hotkey handlers
# -------------------------

func _on_reset_player() -> void:
    if player == null or player_spawn == null:
        return
    player.global_position = player_spawn.global_position
    if print_hotkey_log:
        Debug.log("[EnemyGroupTestbed] Player reset")


func _on_reset_enemies() -> void:
    _clear_groups()
    _spawn_all_groups()
    if print_hotkey_log:
        Debug.log("[EnemyGroupTestbed] Enemies reset")


func _on_kill_all() -> void:
    for child in enemies_root.get_children():
        if is_instance_valid(child):
            child.queue_free()
    _groups.clear()
    if print_hotkey_log:
        Debug.log("[EnemyGroupTestbed] All enemies killed")


# -------------------------
# Spawning
# -------------------------

func _spawn_all_groups() -> void:
    if enemy_scene == null:
        push_error("EnemyGroupTestbed: enemy_scene is not assigned")
        return

    if group_spawn_markers.is_empty():
        push_error("EnemyGroupTestbed: no group_spawn_markers assigned")
        return

    for marker in group_spawn_markers:
        if is_instance_valid(marker):
            _spawn_group_at(marker.global_position)


func _spawn_group_at(pivot: Vector2) -> void:
    var group := EnemyGroup.new()
    group.global_position = pivot  # captured as spawn_pivot in EnemyGroup._ready()
    enemies_root.add_child(group)
    _groups.append(group)
    group.group_depleted.connect(_on_group_depleted.bind(group))

    var rng := RandomNumberGenerator.new()
    rng.randomize()

    for i in range(enemies_per_group):
        var angle  := rng.randf_range(0.0, TAU)
        var dist   := rng.randf_range(spawn_scatter_radius * 0.3, spawn_scatter_radius)
        var offset := Vector2.RIGHT.rotated(angle) * dist

        var enemy := enemy_scene.instantiate() as Enemy
        if enemy == null:
            push_error("EnemyGroupTestbed: enemy_scene did not instantiate to Enemy")
            continue

        enemy.home_position = pivot + offset
        enemies_root.add_child(enemy)
        group.register_member(enemy)


func _clear_groups() -> void:
    for child in enemies_root.get_children():
        if is_instance_valid(child):
            child.queue_free()
    _groups.clear()


# -------------------------
# Group callbacks
# -------------------------

func _on_group_depleted(group: EnemyGroup) -> void:
    _groups.erase(group)
    if print_hotkey_log:
        Debug.log("[EnemyGroupTestbed] Group depleted — %d groups remaining" % _groups.size())


# -------------------------
# Debug UI
# -------------------------

func _update_debug_label() -> void:
    if debug_label == null:
        return

    var lines: Array[String] = []
    lines.append("[R] Reset player   [E] Reset enemies   [K] Kill all")
    lines.append("")

    var total_alive := 0
    for i in range(_groups.size()):
        var g := _groups[i]
        if not is_instance_valid(g):
            continue
        var count := g.get_member_count()
        total_alive += count
        lines.append("Group %d  →  %d alive   center: (%.0f, %.0f)" % [
            i + 1, count, g.get_center().x, g.get_center().y
        ])

    lines.append("")
    lines.append("Total alive: %d" % total_alive)

    debug_label.text = "\n".join(lines)


# -------------------------
# Setup helpers
# -------------------------

func _apply_start_positions() -> void:
    if player != null and player_spawn != null:
        player.global_position = player_spawn.global_position


func _ensure_test_actions() -> void:
    _ensure_key_action(ACTION_RESET_PLAYER,  KEY_R)
    _ensure_key_action(ACTION_RESET_ENEMIES, KEY_E)
    _ensure_key_action(ACTION_KILL_ALL,      KEY_K)


func _ensure_key_action(action_name: StringName, keycode: Key) -> void:
    if InputMap.has_action(action_name):
        return
    InputMap.add_action(action_name)
    var event := InputEventKey.new()
    event.physical_keycode = keycode
    InputMap.action_add_event(action_name, event)
