extends CharacterBody2D
## Player movement and facing. Combat targeting will build on facing_direction.

@export var move_speed: float = 180.0
var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * move_speed
    if direction.length_squared() > 0.001:
        facing_direction = direction.normalized()
    move_and_slide()
    queue_redraw()

func _draw() -> void:
    draw_circle(Vector2.ZERO, 14.0, Color("#d6bd83"))
    draw_circle(facing_direction * 8.0, 4.0, Color("#614d39"))
