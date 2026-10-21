extends CharacterBody2D
## Movement-facing normally; forward-arc target lock while firing.

const ARROW_SCRIPT = preload("res://scripts/arrow.gd")
const TARGET_ARC_DOT := 0.5 # 120 degree full arc
const FIRE_INTERVAL := 0.45
@export var move_speed: float = 180.0

var facing_direction: Vector2 = Vector2.DOWN
var touch_direction: Vector2 = Vector2.ZERO
var touch_attack: bool = false
var locked_facing: Vector2 = Vector2.DOWN
var attacking: bool = false
var target: Node2D = null
var fire_cooldown: float = 0.0

func set_touch_direction(direction: Vector2) -> void:
    touch_direction = direction

func set_touch_attack(pressed: bool) -> void:
    touch_attack = pressed

func _physics_process(delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if touch_direction.length_squared() > 0.001:
        direction = touch_direction
    velocity = direction * move_speed

    var attack_pressed := touch_attack or Input.is_action_pressed("attack")
    if attack_pressed and not attacking:
        attacking = true
        locked_facing = facing_direction
        target = _find_target(locked_facing)
        fire_cooldown = 0.0
    elif not attack_pressed and attacking:
        attacking = false
        target = null

    if attacking:
        if not is_instance_valid(target) or not target.is_in_group("enemies"):
            target = _find_target(locked_facing)
        if is_instance_valid(target):
            facing_direction = global_position.direction_to(target.global_position)
        else:
            facing_direction = locked_facing
        fire_cooldown -= delta
        if fire_cooldown <= 0.0:
            _fire_arrow()
            fire_cooldown = FIRE_INTERVAL
    elif direction.length_squared() > 0.001:
        facing_direction = direction.normalized()

    move_and_slide()
    queue_redraw()

func _find_target(aim_direction: Vector2) -> Node2D:
    var best: Node2D = null
    var best_distance := INF
    for candidate in get_tree().get_nodes_in_group("enemies"):
        var displacement: Vector2 = candidate.global_position - global_position
        var distance := displacement.length()
        if distance < 1.0 or distance > 450.0:
            continue
        if aim_direction.dot(displacement / distance) < TARGET_ARC_DOT:
            continue
        if distance < best_distance:
            best = candidate
            best_distance = distance
    return best

func _fire_arrow() -> void:
    var arrow := Node2D.new()
    arrow.set_script(ARROW_SCRIPT)
    get_parent().add_child(arrow)
    arrow.global_position = global_position + facing_direction * 21.0
    arrow.direction = facing_direction

func _draw() -> void:
    draw_circle(Vector2.ZERO, 14.0, Color("#d6bd83"))
    draw_circle(facing_direction * 8.0, 4.0, Color("#614d39"))
    var sideways := Vector2(-facing_direction.y, facing_direction.x)
    var bow_center := facing_direction * 15.0
    draw_arc(bow_center, 10.0, facing_direction.angle() - 1.2, facing_direction.angle() + 1.2, 12, Color("#ae7844"), 3.0)
    draw_line(bow_center + sideways * 9.0, bow_center - sideways * 9.0, Color("#e5d4ac"), 1.0)
    if attacking and is_instance_valid(target):
        var local_target := to_local(target.global_position)
        draw_arc(local_target, 23.0, 0.0, TAU, 32, Color("#efcc75"), 2.0)
