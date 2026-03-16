# Scratchpad

把揮空與打到東西(沒破防也可)的SFX分開

If player kill some members of group and group despawn after that, it won't count as a complete group in encounter controller

DespawnController
漸進刪除(Minecraft-like)

update enemy to beehave → Simplify

Contact Attack optional self attack direction wrong as they should direction from target not self, also the faction is not right too, I think we should build a new attackData instead use same data.

Attack cool down to stats → Combat module might need dynamic generated attack_module for each attack slot, since there might be two attack as primary and secondary but both melee, and it will break currently flow → But how should I match new flow to persistence attack as they don't need cooldown after all and the hitbox need to match sprite and animation, how do I achieve this with dynamic add attack module?

Create slimes, skelonbow, ork

1. Slime
    - Contact Attack
    - AI
        - Idle
        - Contact
    - No back AI (Chase until died or despawn when leave player too far)
    - Blue → Standard, Green → Bigger but slower
2. Skull
    - Projectile Attack
    - AI
        - Idle
        - Chase
        - Ranged Attack?
        - Retreat
        - Back and Leash Back
    - Blue → Standard, Red → Projectile with small aoe explosion
3. Bear
    - Charge Attack
    - AI
        - Idle
        - Chase
        - Melee Attack?
        - Back and Leash Back
    - No variant

- New Enemy AI?
    - Ranged Attack and Melee Attack AI? Change Chase AI?
        - Maybe I just need modify attack to let halt dist to target can be set, seems attack ai is basically same?
    - Retreat
        - When too close to player, try to leave player from opposite direction
    - Contact
        - Like Chase but arrive dist = 0
