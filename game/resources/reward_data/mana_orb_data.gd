class_name ManaOrbData
extends ResourceRewardData


func execute_effect(collector: Node, amount: int) -> bool:
    if collector == null:
        return false

    if collector.has_method("add_mana"):
        collector.add_mana(amount)
        return true

    return false
