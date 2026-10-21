extends Node2D
## Stationary practice goblin. Can be replaced with an enemy scene later.

const MAX_HEALTH := 5
var health: int = MAX_HEALTH
var alive: bool = true

func _ready() -> void:
    add_to_group("enemies")
    queue_redraw()

func take_hit() -> void:
    if not alive:
        return
    health -= 1
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
    if not alive:
        return
    draw_circle(Vector2.ZERO, 15.0, Color("#618b51"))
    draw_circle(Vector2(-7, -4), 3.0, Color("#e0c88a"))
    draw_circle(Vector2(7, -4), 3.0, Color("#e0c88a"))
    draw_rect(Rect2(-19, -29, 38, 5), Color("#402b2b"))
    draw_rect(Rect2(-19, -29, 38.0 * health / MAX_HEALTH, 5), Color("#a5c86c"))
