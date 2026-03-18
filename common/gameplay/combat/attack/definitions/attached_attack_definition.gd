class_name AttachedAttackDefinition
extends AttackDefinition

## Persistent hitbox that lives on the actor and is toggled on/off externally.
## The hitbox node is pre-authored in the scene and registered in CombatModule.hitbox_slots.
## Geometry and orientation are driven by AnimationPlayer — this definition
## only carries the shared damage/hit fields from AttackDefinition.
##
## Use for: contact damage bodies, charge hitboxes, aura effects, beam weapons.
##
## hitbox_slot_id must match the slot_id on the intended Hitbox node in the scene.
## CombatModule searches hitbox_slots by slot_id at setup time — no ordering required.

@export_group("Hitbox Binding")
## Must match the slot_id set on the target Hitbox node in the inspector (case-sensitive).
@export var hitbox_slot_id: StringName = ""
