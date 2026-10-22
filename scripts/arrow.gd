extends Node2D
const SFX = preload("res://scripts/combat_sfx.gd")
## Swept projectile collision: walls and enemies compete for the earliest impact.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 420.0
var lifetime: float = 2.8

func _ready() -> void:
    modulate.a = 0.0 # IsometricView renders the projected arrow instead.


func _physics_process(delta: float) -> void:
    var previous: Vector2 = global_position
    var endpoint: Vector2 = previous + direction.normalized() * speed * delta
    lifetime -= delta

    var wall_query := PhysicsRayQueryParameters2D.create(previous, endpoint, 1)
    var wall_hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(wall_query)
    var wall_fraction: float = 1.0
    if not wall_hit.is_empty():
        wall_fraction = previous.distance_to(wall_hit["position"]) / maxf(previous.distance_to(endpoint), 0.001)

    var nearest_enemy: Node2D = null
    var enemy_fraction: float = wall_fraction
    var segment: Vector2 = endpoint - previous
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(enemy):
            continue
        var fraction: float = clampf((enemy.global_position - previous).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
        var closest: Vector2 = previous + segment * fraction
        if closest.distance_to(enemy.global_position) <= 17.0 and fraction < enemy_fraction:
            nearest_enemy = enemy
            enemy_fraction = fraction

    if nearest_enemy != null:
        global_position = previous + segment * enemy_fraction
        nearest_enemy.take_hit(2, "piercing")
        queue_free()
        return
    if not wall_hit.is_empty():
        SFX.play(get_parent(), "wall")
        queue_free()
        return

    global_position = endpoint
    if lifetime <= 0.0:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    draw_line(-direction * 9.0, direction * 9.0, Color("#e6c786"), 3.0)
    draw_line(direction * 9.0, direction * 14.0, Color("#e8e8e8"), 2.0)
