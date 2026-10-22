extends RefCounted
## Shared damage resolution for melee and ranged attacks.
const HIT_CHANCE := 0.85
const CRIT_CHANCE := 0.15
const CRIT_MULTIPLIER := 1.75
const BASE_DAMAGE := 2

static func resolve(base_damage: int = BASE_DAMAGE, damage_type: String = "piercing", resistances: Dictionary = {}) -> Dictionary:
    if randf() >= HIT_CHANCE:
        return {"result": "MISS", "damage": 0, "type": damage_type}
    var critical := randf() < CRIT_CHANCE
    var multiplier: float = float(resistances.get(damage_type, 1.0))
    var damage := maxi(0, roundi(float(base_damage) * (CRIT_MULTIPLIER if critical else 1.0) * multiplier))
    return {"result": "RESISTED" if damage == 0 else "CRIT!" if critical else "HIT", "damage": damage, "type": damage_type}
