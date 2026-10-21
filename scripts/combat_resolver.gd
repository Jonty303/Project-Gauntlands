extends RefCounted
## Prototype RPG resolution, called only after physical projectile contact.
const HIT_CHANCE := 0.85
const CRIT_CHANCE := 0.15
const CRIT_MULTIPLIER := 1.75
const BASE_DAMAGE := 2

static func resolve() -> Dictionary:
    if randf() >= HIT_CHANCE:
        return {"result": "MISS", "damage": 0}
    if randf() < CRIT_CHANCE:
        return {"result": "CRIT!", "damage": roundi(BASE_DAMAGE * CRIT_MULTIPLIER)}
    return {"result": "HIT", "damage": BASE_DAMAGE}
