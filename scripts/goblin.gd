extends CharacterBody2D
## Stationary training goblin with prototype RPG feedback.
const CombatResolver = preload("res://scripts/combat_resolver.gd")
const MAX_HEALTH := 10
var health: int = MAX_HEALTH
var alive: bool = true
var combat_text: String = ""
var combat_text_time: float = 0.0
var home: Vector2
var player: Node2D
var state: String = "IDLE"
var last_seen: Vector2
var lost_sight_time: float = 0.0
const SIGHT_RANGE := 260.0
const CHASE_SPEED := 76.0
const RETURN_SPEED := 105.0
const ATTACK_RANGE := 35.0
const MEMORY_SECONDS := 1.2

func _ready() -> void:
    home = global_position
    player = get_tree().get_first_node_in_group("player")
    add_to_group("enemies")
    queue_redraw()

func _process(delta: float) -> void:
    if combat_text_time > 0.0:
        combat_text_time -= delta
        queue_redraw()

func _physics_process(delta: float) -> void:
    if not alive:
        return
    var sees_player: bool = _can_see_player()
    if state == "IDLE" and sees_player:
        state = "CHASE"
    if state == "CHASE":
        if health <= MAX_HEALTH / 4:
            state = "RETURN"
        elif sees_player:
            last_seen = player.global_position
            lost_sight_time = 0.0
        else:
            lost_sight_time += delta
            if lost_sight_time >= MEMORY_SECONDS:
                state = "RETURN"
    if state == "RETURN":
        if global_position.distance_to(home) < 6.0:
            global_position = home
            velocity = Vector2.ZERO
            state = "IDLE"
        else:
            velocity = global_position.direction_to(home) * RETURN_SPEED
    elif state == "CHASE":
        var destination: Vector2 = player.global_position if sees_player else last_seen
        if global_position.distance_to(destination) > ATTACK_RANGE:
            velocity = global_position.direction_to(destination) * CHASE_SPEED
        else:
            velocity = Vector2.ZERO
    else:
        velocity = Vector2.ZERO
    move_and_slide()
    queue_redraw()

func _can_see_player() -> bool:
    if not is_instance_valid(player):
        return false
    if global_position.distance_to(player.global_position) > SIGHT_RANGE:
        return false
    var query := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
    query.exclude = [get_rid()]
    var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    return hit.is_empty() or hit.get("collider") == player

func take_hit() -> void:
    if not alive:
        return
    var result: Dictionary = CombatResolver.resolve()
    var damage: int = result["damage"]
    combat_text = result["result"] if damage == 0 else str(damage) + (" CRIT!" if result["result"] == "CRIT!" else "")
    combat_text_time = 0.7
    health -= damage
    if damage > 0 and health <= MAX_HEALTH / 4 and health > 0:
        state = "RETURN"
    if health <= 0:
        alive = false
        velocity = Vector2.ZERO
        remove_from_group("enemies")
        queue_redraw()
        await get_tree().create_timer(2.0).timeout
        if not is_inside_tree():
            return
        health = MAX_HEALTH
        global_position = home
        state = "IDLE"
        alive = true
        add_to_group("enemies")
    queue_redraw()

func _draw() -> void:
    if alive:
        draw_circle(Vector2.ZERO, 15.0, Color("#618b51"))
        draw_circle(Vector2(-7, -4), 3.0, Color("#e0c88a"))
        draw_circle(Vector2(7, -4), 3.0, Color("#e0c88a"))
        draw_rect(Rect2(-19, -29, 38, 5), Color("#402b2b"))
        draw_rect(Rect2(-19, -29, 38.0 * health / MAX_HEALTH, 5), Color("#a5c86c"))
    if combat_text_time > 0.0:
        draw_string(ThemeDB.fallback_font, Vector2(-22, -39), combat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f4d17d"))
