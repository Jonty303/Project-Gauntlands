extends Node2D
## The node origin is the front edge of the wall footprint.
var wall_size: Vector2 = Vector2(28.0, 210.0)
const HEIGHT := 92.0
const FACE := Color("#353d4b")
const TOP := Color("#78818e")

func _draw() -> void:
    var left := -wall_size.x * 0.5
    var right := wall_size.x * 0.5
    var back := -wall_size.y
    # Counter-rotate camera view: screen-vertical height is -45 degrees in world space.
    var rise := Vector2(0, -HEIGHT).rotated(-PI / 4.0)
    draw_colored_polygon(PackedVector2Array([
        Vector2(left, 0), Vector2(right, 0),
        Vector2(right, 0) + rise, Vector2(left, 0) + rise
    ]), FACE)
    draw_colored_polygon(PackedVector2Array([Vector2(left, back) + rise, Vector2(right, back) + rise, Vector2(right, 0) + rise, Vector2(left, 0) + rise]), TOP)
    draw_line(Vector2(left, 0) + rise, Vector2(right, 0) + rise, Color("#b0a69a"), 3.0)
    draw_line(Vector2(left, back) + rise, Vector2(right, back) + rise, Color("#565c68"), 2.0)
