class_name ArmyStateMachine
extends StateMachine

@onready var target: Node = self.owner


func _ready() -> void:
    if not target.is_node_ready():
        await target.ready

    super._ready()
