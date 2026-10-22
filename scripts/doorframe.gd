extends Node2D
## Front foot of the door is the sorting origin. The opening has no collision.
const OPENING := 90.0
const HEIGHT := 43.0
func _draw() -> void:
    var stone := Color("#8c8276")
    var shadow := Color("#37363c")
    var trim := Color("#c5aa76")
    draw_rect(Rect2(-7, -OPENING - HEIGHT, 14, HEIGHT + 12), shadow)
    draw_rect(Rect2(-7, -HEIGHT + 5, 14, HEIGHT + 12), shadow)
    draw_line(Vector2(-7, -OPENING - HEIGHT), Vector2(-7, -HEIGHT), stone, 5.0)
    draw_line(Vector2(7, -OPENING - HEIGHT), Vector2(7, -HEIGHT), trim, 3.0)
    draw_line(Vector2(-10, -OPENING - HEIGHT), Vector2(10, -OPENING - HEIGHT), trim, 4.0)
    draw_line(Vector2(-10, -HEIGHT), Vector2(10, -HEIGHT), trim, 4.0)
