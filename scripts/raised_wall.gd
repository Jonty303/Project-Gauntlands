extends Node2D
## Stone masonry on both exposed vertical faces and the top of every wall.
## Footprint and collision remain completely separate from this artwork.
var wall_size: Vector2 = Vector2(28.0, 210.0)
const HEIGHT := 92.0
const STONE_FRONT := Color("#59616a")
const STONE_SIDE := Color("#424b56")
const STONE_TOP := Color("#a49e90")
const MORTAR := Color("#343d46")
const HIGHLIGHT := Color("#c2b8a3")

func _draw() -> void:
    var l := -wall_size.x * 0.5
    var r := wall_size.x * 0.5
    var b := -wall_size.y
    var rise := Vector2(0.0, -HEIGHT).rotated(-PI / 4.0)
    var front_left := Vector2(l, 0)
    var front_right := Vector2(r, 0)
    var side_back := Vector2(r, b)
    var back_left := Vector2(l, b)
    # Both visible sides are full-height masonry, not flat strips.
    draw_colored_polygon(PackedVector2Array([front_left, front_right, front_right + rise, front_left + rise]), STONE_FRONT)
    draw_colored_polygon(PackedVector2Array([side_back, front_right, front_right + rise, side_back + rise]), STONE_SIDE)
    draw_colored_polygon(PackedVector2Array([back_left + rise, side_back + rise, front_right + rise, front_left + rise]), STONE_TOP)
    # Horizontal courses on both vertical faces.
    for fraction in [0.25, 0.50, 0.75]:
        var lift := rise * fraction
        draw_line(front_left + lift, front_right + lift, MORTAR, 1.5)
        draw_line(side_back + lift, front_right + lift, MORTAR, 1.5)
    # Staggered vertical joints along the long side.
    var count := maxi(1, int(wall_size.y / 30.0))
    for i in range(1, count):
        var t := float(i) / float(count)
        var point := side_back.lerp(front_right, t)
        draw_line(point + rise * 0.25, point + rise * 0.50, MORTAR, 1.4)
        if i % 2 == 0:
            draw_line(point + rise * 0.50, point + rise * 0.75, MORTAR, 1.4)
        else:
            draw_line(point, point + rise * 0.25, MORTAR, 1.4)
    # Capstones across the top; breaks follow wall length.
    for i in range(1, count):
        var t := float(i) / float(count)
        var a := (back_left + rise).lerp(front_left + rise, t)
        var c := (side_back + rise).lerp(front_right + rise, t)
        draw_line(a, c, Color("#77766f"), 1.5)
    draw_line(front_left + rise, front_right + rise, HIGHLIGHT, 2.5)
    draw_line(side_back + rise, front_right + rise, HIGHLIGHT, 2.0)
