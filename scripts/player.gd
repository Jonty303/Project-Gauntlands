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
var gait_phase: float = 0.0
var visual_facing: Vector2 = Vector2.DOWN
var shot_recoil: float = 0.0
var bow_draw: float = 0.0

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
    _update_animation(delta)
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
    shot_recoil = 1.0
    bow_draw = 0.0

func _update_animation(delta: float) -> void:
    # Keep gameplay responsive while easing the visual pose.
    visual_facing = Vector2.RIGHT.rotated(rotate_toward(visual_facing.angle(), facing_direction.angle(), 10.0 * delta))
    if velocity.length_squared() > 16.0:
        gait_phase += delta * (9.0 + velocity.length() / 55.0)
    bow_draw = move_toward(bow_draw, 1.0 if attacking else 0.0, delta * 5.0)
    shot_recoil = move_toward(shot_recoil, 0.0, delta * 5.0)

func _draw() -> void:
    var forward := visual_facing.normalized()
    var side := Vector2(-forward.y, forward.x)
    var speed_ratio := clampf(velocity.length() / move_speed, 0.0, 1.0)
    var forward_motion := 0.0
    var side_motion := 0.0
    if speed_ratio > 0.05:
        forward_motion = velocity.normalized().dot(forward)
        side_motion = velocity.normalized().dot(side)
    var step_wave := sin(gait_phase) * speed_ratio
    var bounce := absf(sin(gait_phase)) * speed_ratio * 1.4

    # Independent leg stepping: forward, backpedal, or strafe.
    for foot_side in [-1.0, 1.0]:
        var step := step_wave * foot_side
        var foot_position := side * (foot_side * 6.5 + side_motion * step * 3.5)
        foot_position += forward * (-7.0 + forward_motion * step * 5.0 - bounce * 0.5)
        draw_circle(foot_position, 4.5, Color("#403a32"))
        draw_line(foot_position, foot_position + forward * 5.0, Color("#665444"), 3.0)

    var torso_center := forward * (1.5 - shot_recoil * 2.5 - bounce)
    draw_circle(torso_center, 11.0, Color("#64745a"))
    draw_line(torso_center - side * 7.0, torso_center + side * 7.0, Color("#394b3c"), 3.0)
    draw_circle(torso_center + forward * 5.0, 6.5, Color("#d6bd83"))
    draw_circle(torso_center + forward * 9.0, 2.2, Color("#614d39"))

    var bow_center := torso_center + forward * (15.0 - shot_recoil * 4.0) + side * 3.0
    var bow_start := bow_center - side * 10.0
    var bow_end := bow_center + side * 10.0
    draw_arc(bow_center, 10.0, forward.angle() - 1.2, forward.angle() + 1.2, 12, Color("#ae7844"), 3.0)
    var string_pull := bow_center - forward * (bow_draw * 7.0)
    draw_line(bow_start, string_pull, Color("#e5d4ac"), 1.3)
    draw_line(string_pull, bow_end, Color("#e5d4ac"), 1.3)
    if attacking:
        draw_line(string_pull, bow_center + forward * 10.0, Color("#e6c786"), 2.0)

    if attacking and is_instance_valid(target):
        var local_target := to_local(target.global_position)
        draw_arc(local_target, 23.0, 0.0, TAU, 32, Color("#efcc75"), 2.0)
