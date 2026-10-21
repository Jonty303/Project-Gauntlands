extends Node2D

func _draw() -> void:
    draw_rect(Rect2(-400, -270, 800, 540), Color("#242832"))
    for x in range(-400, 401, 40):
        draw_line(Vector2(x, -270), Vector2(x, 270), Color("#343945"))
    for y in range(-270, 271, 40):
        draw_line(Vector2(-400, y), Vector2(400, y), Color("#343945"))
