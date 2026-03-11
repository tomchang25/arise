class_name SoulOrbData
extends ResourceRewardData


func execute_effect(collector: Node, amount: int) -> bool:
    if collector == null:
        return false

    if collector.has_method("add_souls"):
        collector.add_souls(amount)
        return true

    return false
