extends Node

# Simple, robust audio singleton:
# - pooled SFX players (2D + non-positional)
# - a music player
# - limiter to prevent SFX spam per-key

@export_group("Buses")
@export var bus_sfx: StringName = &"SFX"
@export var bus_music: StringName = &"Music"
@export var bus_ui: StringName = &"UI"

@export_group("Pool")
@export var sfx_pool_2d_size: int = 24
@export var sfx_pool_ui_size: int = 8

@export_group("Defaults")
@export var default_pitch_min: float = 0.95
@export var default_pitch_max: float = 1.05

var _music_player: AudioStreamPlayer
var _sfx_2d_pool: Array[AudioStreamPlayer2D] = []
var _ui_pool: Array[AudioStreamPlayer] = []

# key -> Array[tick_msec]
var _rate_history: Dictionary = {}


func _ready() -> void:
    _music_player = AudioStreamPlayer.new()
    _music_player.name = "MusicPlayer"
    _music_player.bus = bus_music
    add_child(_music_player)

    # 2D SFX pool
    for i in range(max(1, sfx_pool_2d_size)):
        var p := AudioStreamPlayer2D.new()
        p.name = "Sfx2D_%02d" % i
        p.bus = bus_sfx
        p.finished.connect(func(): p.stream = null)
        add_child(p)
        _sfx_2d_pool.append(p)

    # UI / non-positional SFX pool
    for i in range(max(1, sfx_pool_ui_size)):
        var u := AudioStreamPlayer.new()
        u.name = "UiSfx_%02d" % i
        u.bus = bus_ui
        u.finished.connect(func(): u.stream = null)
        add_child(u)
        _ui_pool.append(u)


# -------------------------
# Public API
# -------------------------


func play_music(stream: AudioStream, volume_db: float = 0.0, from_sec: float = 0.0) -> void:
    if stream == null:
        return
    _music_player.stop()
    _music_player.stream = stream
    _music_player.volume_db = volume_db
    _music_player.play(from_sec)


func stop_music() -> void:
    _music_player.stop()


func play_ui(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
    if stream == null:
        return
    var p := _get_free_ui_player()
    if p == null:
        return
    p.stop()
    p.stream = stream
    p.volume_db = volume_db
    p.pitch_scale = pitch
    p.play()


func play_sfx_2d(stream: AudioStream, world_pos: Vector2, volume_db: float = 0.0, pitch: float = -1.0) -> void:
    if stream == null:
        return
    var p := _get_free_sfx_2d_player()
    if p == null:
        return
    p.stop()
    p.stream = stream
    p.global_position = world_pos
    p.volume_db = volume_db
    p.pitch_scale = pitch if pitch > 0.0 else randf_range(default_pitch_min, default_pitch_max)
    p.play()


func play_sfx_limited(
    stream: AudioStream, key: StringName, world_pos: Vector2, max_per_window: int = 4, window_sec: float = 0.05, volume_db: float = 0.0, pitch: float = -1.0
) -> void:
    if stream == null:
        return
    if _is_rate_limited(key, max_per_window, window_sec):
        return
    play_sfx_2d(stream, world_pos, volume_db, pitch)


func play_event(event: AudioEvent, world_pos: Vector2 = Vector2.ZERO) -> void:
    if event == null:
        return

    var stream := event.pick_stream()
    if stream == null:
        return

    var pitch := randf_range(event.pitch_min, event.pitch_max)

    if event.limiter_key != &"":
        play_sfx_limited(stream, event.limiter_key, world_pos, event.max_per_window, event.window_sec, event.volume_db, pitch)
    else:
        play_sfx_2d(stream, world_pos, event.volume_db, pitch)


# -------------------------
# Internals
# -------------------------


func _get_free_sfx_2d_player() -> AudioStreamPlayer2D:
    for p in _sfx_2d_pool:
        if not p.playing:
            return p
    # If all busy, reuse the oldest/first (cheap fallback)
    return _sfx_2d_pool[0] if not _sfx_2d_pool.is_empty() else null


func _get_free_ui_player() -> AudioStreamPlayer:
    for p in _ui_pool:
        if not p.playing:
            return p
    return _ui_pool[0] if not _ui_pool.is_empty() else null


func _is_rate_limited(key: StringName, max_per_window: int, window_sec: float) -> bool:
    if key == &"":
        # No key => no limiting
        return false

    var now := Time.get_ticks_msec()
    var window_msec := int(max(0.0, window_sec) * 1000.0)

    var arr: Array = _rate_history.get(key, [])
    # prune old
    var kept: Array = []
    for t in arr:
        if now - int(t) <= window_msec:
            kept.append(t)
    arr = kept

    if arr.size() >= max(0, max_per_window):
        _rate_history[key] = arr
        return true

    arr.append(now)
    _rate_history[key] = arr
    return false
