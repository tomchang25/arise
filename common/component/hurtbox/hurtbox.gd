## Hurtbox.gd
class_name Hurtbox
extends Area2D

signal hit_enemy

# @onready var bullet: Node2D = get_owner()  # Use Node2D for more flexibility than Bullet

@export var attack_data: AttackData

var enabled = true:
    set(value):
        enabled = value
        set_deferred("monitoring", value)


func _ready() -> void:
    if attack_data == null:
        push_error("Hurtbox must have an AttackData resource assigned")
        return

    area_entered.connect(on_area_entered)


func on_area_entered(area: Area2D):
    if not enabled:
        return

    if area is Hitbox:
        var attack_instance := Attack.new()

        attack_instance.data = attack_data
        attack_instance.damage = attack_data.base_damage

        # if bullet.has_method("get_damage_modifier"):
        #     var modifier = bullet.get_damage_modifier()
        #     attack_instance.damage *= modifier  # Modify damage by the current bullet's amplitude/state

        area.damage(attack_instance)

        hit_enemy.emit()
