class_name GoldData
extends ResourceData


func execute_effect(collector: Node, amount: int) -> bool:
    if collector == null:
        return false

    if collector.has_method("add_gold"):
        collector.add_gold(amount)
        return true

    return false
