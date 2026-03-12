class_name HealthOrbData
extends ResourceData


func execute_effect(collector: Node, amount: int) -> bool:
    if collector == null:
        return false

    if collector.has_method("heal"):
        collector.heal(amount)
        return true

    return false
