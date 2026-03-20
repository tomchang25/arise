## Activates a contact (AttachedAttackDefinition) hitbox while the player is in reach.
## The hitbox remains active for as long as this action returns RUNNING.
## Returns FAILURE when the player moves out of reach, which deactivates the hitbox.
class_name ContactAttackAction
extends ActionLeaf

@export var weapon_index: int = 0
@export var attack_index: int = 0

var _is_active: bool = false


func before_run(actor: Node, _blackboard: Blackboard) -> void:
    _activate(actor)


func tick(actor: Node, _blackboard: Blackboard) -> int:
    var enemy := actor as Enemy
    if enemy == null:
        return FAILURE

    if not enemy.is_player_in_reach():
        _deactivate(actor)
        return FAILURE

    if not _is_active:
        _activate(actor)

    enemy.stop_movement()
    return RUNNING


func after_run(actor: Node, _blackboard: Blackboard) -> void:
    _deactivate(actor)


func interrupt(actor: Node, blackboard: Blackboard) -> void:
    _deactivate(actor)
    super(actor, blackboard)


func _activate(actor: Node) -> void:
    var enemy := actor as Enemy
    if enemy == null or _is_active:
        return
    # can_attack() returns false while the hitbox is already active.
    if enemy.can_attack(weapon_index, attack_index):
        enemy.activate_attack(weapon_index, attack_index)
        _is_active = true


func _deactivate(actor: Node) -> void:
    var enemy := actor as Enemy
    if enemy == null or not _is_active:
        return
    enemy.deactivate_attack(weapon_index, attack_index)
    _is_active = false
