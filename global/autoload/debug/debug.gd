extends Node

const FORCE_DEBUG := true
var enabled := FORCE_DEBUG or OS.is_debug_build()

# -------------------------
# Internal
# -------------------------


func _caller() -> String:
    var stack = get_stack()
    if stack.size() > 2:
        var s = stack[2]
        var script_src = s.get("source", "")
        var func_name = s.get("function", "")
        return "%s::%s" % [script_src.get_file(), func_name]
    return "unknown"

# -------------------------
# Raw Debug
# -------------------------


func get_caller() -> String:
    var stack = get_stack()
    if stack.size() > 2:
        var s = stack[2]
        var script_src = s.get("source", "")
        var func_name = s.get("function", "")
        return "%s::%s" % [script_src.get_file(), func_name]
    return "unknown"


func debug(msg: Variant) -> void:
    if not enabled:
        return
    print_debug(msg)

# -------------------------
# Structured Logs
# -------------------------


func log(msg: Variant) -> void:
    if not enabled:
        return
    print("[Log] %s -> %s" % [_caller(), msg])


func warn(msg: Variant) -> void:
    if not enabled:
        return
    push_warning("[WARN] %s -> %s" % [_caller(), msg])


func invalid(msg: Variant) -> void:
    if not enabled:
        return
    push_error("[INVALID] %s -> %s" % [_caller(), msg])
