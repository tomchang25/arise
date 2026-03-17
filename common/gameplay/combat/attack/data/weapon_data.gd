class_name WeaponData
extends Resource

## A weapon owned by an actor. Contains one or more AttackDefinitions.
##
## Index 0 = "primary" attack (player left-click, enemy default attack).
## Index 1 = "secondary" attack (player right-click, enemy alt attack).
## Further indices are extra attacks specific to that weapon.
##
## Multiple weapons on the same actor are independent — each gets its own
## executor set and can fire simultaneously with other weapons.

@export var weapon_name: String = ""

## All attacks this weapon can perform, indexed by attack slot.
## Most enemies will have a single entry. Player weapons typically have two.
@export var attacks: Array[AttackDefinition] = []
