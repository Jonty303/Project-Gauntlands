
extends CharacterBody2D
## Goblin AI: sight, pursuit, melee, retreat and return home.

const SFX = preload("res://scripts/combat_sfx.gd")
const CombatResolver = preload("res://scripts/combat_resolver.gd")

const MAX_HEALTH := 10
const SIGHT_RANGE := 260.0
const MELEE_RANGE := 35.0
const CHASE_SPEED := 65.0
const RETURN_SPEED := 105.0
const MEMORY_SECONDS := 3.0
const WINDUP_TIME := 0.55
const ATTACK_COOLDOWN := 1.25

var health: int = MAX_HEALTH
var alive: bool = true
var home: Vector2
var player: Node2D
var state: String = "IDLE"
var debug_ai: bool = false
var destination_marker: Vector2 = Vector2.ZERO
var has_destination: bool = false
var last_seen: Vector2 = Vector2.ZERO
var lost_sight_time: float = 0.0

var attack_timer: float = 0.0
var windup_timer: float = 0.0
var winding_up: bool = false
var combat_text: String = ""
var combat_text_time: float = 0.0

func _ready() -> void:
    home = global_position
    player = get_parent().get_node_or_null("Player") as Node2D
    add_to_group("enemies")
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
        debug_ai = not debug_ai
        queue_redraw()

func _physics_process(delta: float) -> void:
    combat_text_time = maxf(0.0, combat_text_time - delta)
    attack_timer = maxf(0.0, attack_timer - delta)

    if not alive or not is_instance_valid(player):
        velocity = Vector2.ZERO
        queue_redraw()
        return

    var sees_player: bool = _can_see_player()
    var distance: float = global_position.distance_to(player.global_position)

    if state == "IDLE":
        if sees_player and health > MAX_HEALTH / 4:
            state = "CHASE"
            last_seen = player.global_position
            lost_sight_time = 0.0

    elif state == "CHASE":
        if health <= MAX_HEALTH / 4:
            _begin_return()
        elif sees_player:
            last_seen = player.global_position
            lost_sight_time = 0.0
        else:
            lost_sight_time += delta
            if global_position.distance_to(last_seen) < MELEE_RANGE or lost_sight_time >= MEMORY_SECONDS:
                _begin_return()

    velocity = Vector2.ZERO
    has_destination = false

    if state == "CHASE":
        if winding_up:
            windup_timer -= delta
            if windup_timer <= 0.0:
                winding_up = false
                attack_timer = ATTACK_COOLDOWN
                if sees_player and distance <= MELEE_RANGE + 10.0:
                    if player.has_method("take_damage"):
                        player.take_damage(1)
        elif sees_player and distance <= MELEE_RANGE:
            if attack_timer <= 0.0:
                winding_up = true
                windup_timer = WINDUP_TIME
        else:
            var destination: Vector2 = player.global_position if sees_player else last_seen
            if global_position.distance_to(destination) > MELEE_RANGE:
                _navigate_towards(destination, CHASE_SPEED)

    elif state == "RETURN":
        var home_distance: float = global_position.distance_to(home)
        if home_distance < 6.0:
            global_position = home
            state = "IDLE"
        else:
            _navigate_towards(home, minf(RETURN_SPEED, home_distance / delta))

    move_and_slide()
    queue_redraw()

func _navigate_towards(destination: Vector2, speed: float) -> void:
    destination_marker = destination
    has_destination = true
    var waypoint: Vector2 = destination
    if get_parent().has_method("navigation_step"):
        waypoint = get_parent().navigation_step(global_position, destination)
    if global_position.distance_to(waypoint) > 2.0:
        velocity = global_position.direction_to(waypoint) * speed

func _begin_return() -> void:
    state = "RETURN"
    winding_up = false
    windup_timer = 0.0

func _can_see_player() -> bool:
    if not is_instance_valid(player):
        return false
    if global_position.distance_to(player.global_position) > SIGHT_RANGE:
        return false

    var query := PhysicsRayQueryParameters2D.create(
        global_position, player.global_position, 1
    )
    query.exclude = [get_rid()]
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.get("collider") == player

func take_hit(base_damage: int = 2, damage_type: String = "piercing") -> void:
    if not alive:
        return

    var result: Dictionary = CombatResolver.resolve(base_damage, damage_type, {})
    var damage: int = result["damage"]
    combat_text = result["result"] if damage == 0 else str(damage) + (" CRIT!" if result["result"] == "CRIT!" else "")
    combat_text_time = 0.7
    if damage > 0:
        SFX.play(self, "hit")
    health -= damage

    if health <= 0:
        alive = false
        winding_up = false
        velocity = Vector2.ZERO
        remove_from_group("enemies")
        queue_redraw()
        await get_tree().create_timer(2.0).timeout
        if not is_inside_tree():
            return
        health = MAX_HEALTH
        global_position = home
        state = "IDLE"
        lost_sight_time = 0.0
        alive = true
        add_to_group("enemies")
    elif health <= MAX_HEALTH / 4:
        _begin_return()

    queue_redraw()

func _draw() -> void:
    draw_set_transform(Vector2.ZERO, -PI / 4.0)
    if debug_ai and alive:
        var debug_color := Color("#72dca3") if state == "CHASE" else Color("#e3b76a") if state == "RETURN" else Color("#b3bac8")
        draw_string(ThemeDB.fallback_font, Vector2(-22, -55), state, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, debug_color)
        if has_destination:
            draw_line(Vector2.ZERO, to_local(destination_marker), debug_color, 1.5)
            draw_circle(to_local(destination_marker), 4.0, debug_color)
        if is_instance_valid(player):
            draw_line(Vector2.ZERO, to_local(player.global_position), Color("#72dca3") if _can_see_player() else Color("#a54b4b"), 1.0)
    if alive:
        draw_ellipse_shadow()
        draw_circle(Vector2(2, -10), 14.0, Color("#385438"))
        draw_circle(Vector2.ZERO + Vector2(0, -10), 12.0, Color("#b97b4a") if winding_up else Color("#618b51"))
        draw_colored_polygon(PackedVector2Array([Vector2(-10, -16), Vector2(-21, -22), Vector2(-12, -7)]), Color("#537d46"))
        draw_colored_polygon(PackedVector2Array([Vector2(10, -16), Vector2(21, -22), Vector2(12, -7)]), Color("#537d46"))
        draw_line(Vector2(-7, -4), Vector2(-9, 8), Color("#40372d"), 5.0)
        draw_line(Vector2(7, -4), Vector2(9, 8), Color("#40372d"), 5.0)
        draw_circle(Vector2(-7, -13), 3.0, Color("#e0c88a"))
        draw_circle(Vector2(7, -13), 3.0, Color("#e0c88a"))
        draw_rect(Rect2(-19, -29, 38, 5), Color("#402b2b"))
        draw_rect(Rect2(-19, -29, 38.0 * health / MAX_HEALTH, 5), Color("#a5c86c"))
        if winding_up:
            draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 24, Color("#f4a35d"), 2.5)

    if combat_text_time > 0.0:
        draw_string(
            ThemeDB.fallback_font,
            Vector2(-22, -39),
            combat_text,
            HORIZONTAL_ALIGNMENT_LEFT,
            -1,
            13,
            Color("#f4d17d")
        )

func draw_ellipse_shadow() -> void:
    draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.0, 0.38))
    draw_circle(Vector2.ZERO, 18.0, Color(0.03, 0.04, 0.05, 0.45))
    draw_set_transform(Vector2.ZERO, -PI / 4.0)
