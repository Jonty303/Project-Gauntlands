extends Node2D
## Simple moving arrow with a single-target hit test.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var lifetime: float = 1.5

func _process(delta: float) -> void:
    var previous := global_position
    global_position += direction * speed * delta
    lifetime -= delta
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, previous, global_position)
        if closest.distance_to(enemy.global_position) <= 17.0:
            enemy.take_hit()
            queue_free()
            return
    if lifetime <= 0.0 or absf(global_position.x) >= 388.0 or absf(global_position.y) >= 258.0:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    draw_line(-direction * 9.0, direction * 9.0, Color("#e6c786"), 3.0)
    draw_line(direction * 9.0, direction * 14.0, Color("#e8e8e8"), 2.0)
