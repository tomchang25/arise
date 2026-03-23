extends Node

## Global spawn stagger manager.
## Callers enqueue a request with a channel key and a Callable.
## The singleton drains each channel at its configured interval.
##
## Usage:
##   SpawnThrottle.enqueue("damage_number", func(): spawn_damage_number(amount, info))

signal slot_executed(channel: StringName)

const DEFAULT_INTERVAL := 0.05  # seconds between slots per channel

# { channel -> { interval: float, timer: float, queue: Array[Callable] } }
var _channels: Dictionary = {}


func _process(delta: float) -> void:
    for channel in _channels.keys():
        var data: Dictionary = _channels[channel]
        if data.queue.is_empty():
            continue

        data.timer -= delta
        if data.timer > 0.0:
            continue

        data.timer = data.interval
        var fn: Callable = data.queue.pop_front()
        fn.call()
        slot_executed.emit(channel)


## Enqueue a spawn callable under a channel.
## Returns immediately — execution is deferred to the next available slot.
func enqueue(channel: StringName, fn: Callable, interval: float = DEFAULT_INTERVAL) -> void:
    if not _channels.has(channel):
        _channels[channel] = { "interval": interval, "timer": 0.0, "queue": [] }
    _channels[channel].queue.append(fn)


## Clears all pending requests for a channel.
## Call this on encounter end or scene change to prevent stale spawns.
func clear(channel: StringName) -> void:
    if _channels.has(channel):
        _channels[channel].queue.clear()


## Clears all channels. Safe to call on scene reset.
func clear_all() -> void:
    for channel in _channels.keys():
        _channels[channel].queue.clear()
