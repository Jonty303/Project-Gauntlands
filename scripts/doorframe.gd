extends Node2D
## An open stone portal aligned to the actual 90-unit collision gap.
## Origin sits at the doorway centre; neither jamb blocks movement.
const HALF_OPENING := 45.0
const PILLAR_WIDTH := 15.0
const HEIGHT := 92.0
const STONE := Color("#817f79")
const SHADE := Color("#484b50")
const LIGHT := Color("#b9b4a6")
const MORTAR := Color("#45454a")

func _draw() -> void:
    var rise := Vector2(0.0, -HEIGHT).rotated(-PI / 4.0)
    for side in [-1.0, 1.0]:
        var y := side * (HALF_OPENING + PILLAR_WIDTH * 0.5)
        var base := Vector2(0.0, y)
        var left := base + Vector2(-PILLAR_WIDTH * 0.5, -PILLAR_WIDTH * 0.5)
        var right := base + Vector2(PILLAR_WIDTH * 0.5, PILLAR_WIDTH * 0.5)
        var front_a := Vector2(left.x, right.y)
        var front_b := right
        var side_a := Vector2(right.x, left.y)
        draw_colored_polygon(PackedVector2Array([front_a, front_b, front_b + rise, front_a + rise]), SHADE)
        draw_colored_polygon(PackedVector2Array([side_a, front_b, front_b + rise, side_a + rise]), STONE)
        draw_colored_polygon(PackedVector2Array([left + rise, side_a + rise, right + rise, front_a + rise]), LIGHT)
        for band in [0.30, 0.62]:
            var offset := rise * band
            draw_line(front_a + offset, front_b + offset, MORTAR, 1.5)
            draw_line(side_a + offset, front_b + offset, MORTAR, 1.5)
    # Threshold is a floor marking only: leave the entire portal open.
    draw_line(Vector2(0, -HALF_OPENING), Vector2(0, HALF_OPENING), Color("#ac8e61"), 3.0)
