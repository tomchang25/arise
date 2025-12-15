extends Node2D

var check_timer = Timer.new()


func _ready():
    check_timer.wait_time = 0.5
    check_timer.autostart = true
    check_timer.one_shot = false
    check_timer.timeout.connect(_on_check_timer_timeout)
    add_child(check_timer)


func _on_check_timer_timeout():
    var armies_state = {&"Follow": 0, &"Chase": 0, &"Idle": 0, &"Attack": 0}
    for army in get_children():
        if army is not CharacterBody2D:
            continue

        var army_current_state = army.get_current_state()
        if army_current_state.name not in armies_state:
            armies_state[army_current_state.name] = 1
        else:
            armies_state[army_current_state.name] += 1

    print(armies_state)
