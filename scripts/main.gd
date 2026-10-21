extends Node2D

var player_position := Vector2.ZERO
var speed := 180.0

func _process(delta: float) -> void:
    var direction := Input.get_vector(
        "ui_left", "ui_right",
	"ui_up", "ui_down"
    )

    player_position += direction * speed * delta
    player_position = player_position.clamp(
        Vector2(-350, -220),
        Vector2(350, 220)
    )

    queue_redraw()

func _draw() -> void:
    # Dungeon floor
    draw_rect(
        Rect2(-400, -270, 800, 540),
        Color("#242832")
    )

    # Floor grid
    for x in range(-400, 401, 40):
        draw_line(
        Vector2(x, -270),
        Vector2(x, 270),
       Color("#343945")
    )

    for y in range(-270, 271, 40):
        draw_line(
        Vector2(-400, y),
        Vector2(400, y),
       Color("#343945")
    )

    # Player
    draw_circle(
        player_position,
        14,
        Color("#d6bd83")
    )

# Facing indicator
    draw_circle(
        player_position + Vector2(0, -7),
        4,
        Color("#614d39")
    )

