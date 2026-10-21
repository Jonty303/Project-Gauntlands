extends Node2D
## Stationary training goblin with prototype RPG feedback.
const CombatResolver = preload("res://scripts/combat_resolver.gd")
const MAX_HEALTH := 10
var health: int = MAX_HEALTH
var alive: bool = true
var combat_text: String = ""
var combat_text_time: float = 0.0

func _ready() -> void:
    add_to_group("enemies")
    queue_redraw()

func _process(delta: float) -> void:
    if combat_text_time > 0.0:
        combat_text_time -= delta
        queue_redraw()

func take_hit() -> void:
    if not alive:
        return
    var result: Dictionary = CombatResolver.resolve()
    var damage: int = result["damage"]
    combat_text = result["result"] if damage == 0 else str(damage) + (" CRIT!" if result["result"] == "CRIT!" else "")
    combat_text_time = 0.7
    health -= damage
    if health <= 0:
        alive = false
        remove_from_group("enemies")
        queue_redraw()
        await get_tree().create_timer(2.0).timeout
        if not is_inside_tree():
            return
        health = MAX_HEALTH
        alive = true
        add_to_group("enemies")
    queue_redraw()

func _draw() -> void:
    if alive:
        draw_circle(Vector2.ZERO, 15.0, Color("#618b51"))
        draw_circle(Vector2(-7, -4), 3.0, Color("#e0c88a"))
        draw_circle(Vector2(7, -4), 3.0, Color("#e0c88a"))
        draw_rect(Rect2(-19, -29, 38, 5), Color("#402b2b"))
        draw_rect(Rect2(-19, -29, 38.0 * health / MAX_HEALTH, 5), Color("#a5c86c"))
    if combat_text_time > 0.0:
        draw_string(ThemeDB.fallback_font, Vector2(-22, -39), combat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f4d17d"))
