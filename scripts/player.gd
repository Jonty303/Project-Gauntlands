extends CharacterBody2D
## Persistent next selection, independent of the enemy committed to this hold.

const SFX = preload("res://scripts/combat_sfx.gd")
const INPUT_BUFFER := 0.14
var input_buffer: float = 0.0
var previous_attack_pressed: bool = false
const ARROW_SCRIPT = preload("res://scripts/arrow.gd")
const TARGET_ARC_DOT := 0.5 # 120-degree acquisition arc
const MAX_TARGET_RANGE := 450.0
const FIRE_INTERVAL := 0.45
const SWORD_INTERVAL := 0.65
const SWORD_RANGE := 54.0
const SWORD_ARC_DOT := 0.35
var weapon_mode: String = "bow"
var swing_time: float = 0.0
@export var move_speed: float = 180.0

var facing_direction: Vector2 = Vector2.DOWN

func _ready() -> void:
    add_to_group("player")
var touch_direction: Vector2 = Vector2.ZERO
var touch_attack: bool = false
var locked_facing: Vector2 = Vector2.DOWN
var attacking: bool = false
var target: Node2D = null
var soft_target: Node2D = null
var attack_exhausted: bool = false
var attack_has_target: bool = false
var fire_cooldown: float = 0.0
var gait_phase: float = 0.0
var visual_facing: Vector2 = Vector2.DOWN
var shot_recoil: float = 0.0
var bow_draw: float = 0.0
const MAX_HEALTH := 8
const INVULNERABILITY_TIME := 0.7
var health: int = MAX_HEALTH
var invulnerability_timer: float = 0.0
var defeated: bool = false

func set_touch_direction(direction: Vector2) -> void:
    touch_direction = direction

func set_touch_attack(pressed: bool) -> void:
    touch_attack = pressed

func take_damage(amount: int) -> void:
    if defeated or invulnerability_timer > 0.0:
        return
    health = maxi(0, health - amount)
    invulnerability_timer = INVULNERABILITY_TIME
    if health == 0:
        defeated = true
        attacking = false
        touch_attack = false
    SFX.play(self, "hurt")
    queue_redraw()

func _physics_process(delta: float) -> void:
    invulnerability_timer = maxf(0.0, invulnerability_timer - delta)
    if defeated:
        velocity = Vector2.ZERO
        queue_redraw()
        if Input.is_action_just_pressed("ui_accept"):
            get_tree().reload_current_scene()
        return
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if touch_direction.length_squared() > 0.001:
        direction = touch_direction
    # Screen-relative controls converted to logical world-space motion.
    if direction.length_squared() > 0.001:
        var screen_x: float = direction.x / 0.82
        var screen_y: float = direction.y / 0.41
        direction = Vector2((screen_x + screen_y) * 0.5, (screen_y - screen_x) * 0.5).normalized()
    velocity = direction * move_speed

    if Input.is_action_just_pressed("weapon_toggle"):
        toggle_weapon()
    var attack_pressed: bool = touch_attack or Input.is_action_pressed("attack")
    fire_cooldown = maxf(0.0, fire_cooldown - delta)
    input_buffer = maxf(0.0, input_buffer - delta)
    if attack_pressed and not previous_attack_pressed:
        input_buffer = INPUT_BUFFER
    previous_attack_pressed = attack_pressed
    if not attack_pressed and direction.length_squared() > 0.001:
        facing_direction = direction.normalized()
    # Refresh before cycling/pressing, including the very first physics frame.
    _refresh_soft_target()
    if Input.is_action_just_pressed("target_previous"):
        _cycle_target(-1)
    elif Input.is_action_just_pressed("target_next"):
        _cycle_target(1)

    if not attack_pressed:
        attacking = false
        attack_exhausted = false
        attack_has_target = false
        target = null
    elif not attacking and not attack_exhausted:
        attacking = true
        target = soft_target if weapon_mode == "bow" and _is_enemy_available(soft_target) else null
        attack_has_target = is_instance_valid(target)
        locked_facing = facing_direction

    if attacking:
        # Range affects the next selection, never this hold's commitment.
        if attack_has_target and not _is_enemy_alive(target):
            attacking = false
            attack_exhausted = true
            target = null
            _refresh_soft_target()
        elif target != null:
            facing_direction = global_position.direction_to(target.global_position)
        else:
            facing_direction = locked_facing

        if attacking:
            if fire_cooldown <= 0.0 and (attack_pressed or input_buffer > 0.0):
                input_buffer = 0.0
                if weapon_mode == "bow":
                    _fire_arrow()
                    fire_cooldown = FIRE_INTERVAL
                else:
                    _swing_sword()
                    fire_cooldown = SWORD_INTERVAL

    swing_time = maxf(0.0, swing_time - delta)
    move_and_slide()
    _refresh_soft_target()
    _update_animation(delta)
    queue_redraw()

func _is_enemy_alive(enemy: Variant) -> bool:
    return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.is_in_group("enemies")

func _is_enemy_available(enemy: Variant) -> bool:
    return _is_enemy_alive(enemy) and global_position.distance_to(enemy.global_position) <= MAX_TARGET_RANGE and _has_clear_shot(enemy)

func _has_clear_shot(enemy: Node2D) -> bool:
    var query := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
    query.exclude = [get_rid()]
    return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _refresh_soft_target() -> void:
    if _is_enemy_available(soft_target):
        return
    soft_target = _find_target(facing_direction)

func _find_target(aim_direction: Vector2) -> Node2D:
    var best: Node2D = null
    var best_distance: float = INF
    var nearest: Node2D = null
    var nearest_distance: float = INF
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not _is_enemy_available(candidate):
            continue
        var displacement: Vector2 = candidate.global_position - global_position
        var distance: float = displacement.length()
        if distance < nearest_distance:
            nearest = candidate
            nearest_distance = distance
        if distance > 0.0 and aim_direction.normalized().dot(displacement / distance) < TARGET_ARC_DOT:
            continue
        if distance < best_distance:
            best = candidate
            best_distance = distance
    return best if best != null else nearest

func _cycle_target(step: int) -> void:
    var candidates: Array[Node2D] = []
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if _is_enemy_available(enemy):
            candidates.append(enemy)
    if candidates.is_empty():
        soft_target = null
        return
    candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
        return global_position.direction_to(a.global_position).angle() < global_position.direction_to(b.global_position).angle())
    var index: int = candidates.find(soft_target)
    if index < 0:
        soft_target = candidates[0]
    else:
        soft_target = candidates[posmod(index + step, candidates.size())]

func toggle_weapon() -> void:
    weapon_mode = "sword" if weapon_mode == "bow" else "bow"
    SFX.play(self, "switch")
    # A held attack cannot silently acquire a new target after switching.
    if attacking:
        attacking = false
        attack_exhausted = true
        target = null
    queue_redraw()

func _swing_sword() -> void:
    SFX.play(self, "swing")
    swing_time = 0.22
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if not _is_enemy_alive(enemy):
            continue
        var offset: Vector2 = enemy.global_position - global_position
        if offset.length() <= SWORD_RANGE and (offset.length_squared() < 0.01 or facing_direction.normalized().dot(offset.normalized()) >= SWORD_ARC_DOT):
            if enemy.has_method("take_hit"):
                enemy.take_hit(3, "slashing")

func _fire_arrow() -> void:
    SFX.play(self, "bow")
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
    draw_rect(Rect2(-28, -45, 56, 6), Color("#402b2b"))
    draw_rect(Rect2(-28, -45, 56.0 * health / MAX_HEALTH, 6), Color("#c65d54"))
    if defeated:
        draw_string(ThemeDB.fallback_font, Vector2(-42, -60), "DEFEATED", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f4d17d"))
        draw_string(ThemeDB.fallback_font, Vector2(-75, 55), "Press Enter to restart", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)
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
    for foot_side: float in [-1.0, 1.0]:
        var step: float = step_wave * foot_side
        var foot_position: Vector2 = side * (foot_side * 6.5 + side_motion * step * 3.5)
        foot_position += forward * (-7.0 + forward_motion * step * 5.0 - bounce * 0.5)
        draw_circle(foot_position, 4.5, Color("#403a32"))
        draw_line(foot_position, foot_position + forward * 5.0, Color("#665444"), 3.0)

    var torso_center := forward * (1.5 - shot_recoil * 2.5 - bounce)
    draw_circle(torso_center, 11.0, Color("#64745a"))
    draw_line(torso_center - side * 7.0, torso_center + side * 7.0, Color("#394b3c"), 3.0)
    draw_circle(torso_center + forward * 5.0, 6.5, Color("#d6bd83"))
    draw_circle(torso_center + forward * 9.0, 2.2, Color("#614d39"))

    if weapon_mode == "sword":
        var blade_base := torso_center + forward * 12.0 + side * 5.0
        draw_line(blade_base, blade_base + forward * 25.0, Color("#d6d9de"), 4.0)
        draw_line(blade_base - side * 7.0, blade_base + side * 7.0, Color("#a77a45"), 3.0)
        if swing_time > 0.0:
            draw_arc(Vector2.ZERO, SWORD_RANGE, facing_direction.angle() - acos(SWORD_ARC_DOT), facing_direction.angle() + acos(SWORD_ARC_DOT), 20, Color("#e7d7a0"), 3.0)
    else:
        _draw_bow(torso_center, forward, side)
    draw_string(ThemeDB.fallback_font, Vector2(-37, 42), "SWORD" if weapon_mode == "sword" else "BOW", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f4d17d"))

    # Different radii and labels keep both roles visible on the same enemy.
    if weapon_mode == "bow" and _is_enemy_available(soft_target):
        var next_position: Vector2 = to_local(soft_target.global_position)
        draw_arc(next_position, 28.0, 0.0, TAU, 32, Color("#91c7d6"), 2.0)
        draw_string(ThemeDB.fallback_font, next_position + Vector2(-16, 42), "NEXT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#91c7d6"))
    if weapon_mode == "bow" and attacking and _is_enemy_alive(target):
        var active_position: Vector2 = to_local(target.global_position)
        draw_arc(active_position, 22.0, 0.0, TAU, 32, Color("#efcc75"), 3.0)
        draw_string(ThemeDB.fallback_font, active_position + Vector2(-23, -52), "ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#efcc75"))

func _draw_bow(torso_center: Vector2, forward: Vector2, side: Vector2) -> void:
    var bow_center := torso_center + forward * (15.0 - shot_recoil * 4.0) + side * 3.0
    var bow_start := bow_center - side * 10.0
    var bow_end := bow_center + side * 10.0
    draw_arc(bow_center, 10.0, forward.angle() - 1.2, forward.angle() + 1.2, 12, Color("#ae7844"), 3.0)
    var string_pull := bow_center - forward * (bow_draw * 7.0)
    draw_line(bow_start, string_pull, Color("#e5d4ac"), 1.3)
    draw_line(string_pull, bow_end, Color("#e5d4ac"), 1.3)
    if attacking:
        draw_line(string_pull, bow_center + forward * 10.0, Color("#e6c786"), 2.0)

