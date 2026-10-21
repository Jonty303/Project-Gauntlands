extends Node2D
## Pursuing goblin with a readable wind-up before melee strikes.
const CombatResolver = preload("res://scripts/combat_resolver.gd")
const MAX_HEALTH := 10
const DETECTION_RANGE := 260.0
const MELEE_RANGE := 35.0
const MOVE_SPEED := 65.0
const WINDUP_TIME := 0.55
const ATTACK_COOLDOWN := 1.25
var health: int = MAX_HEALTH
var alive: bool = true
var combat_text: String = ""
var combat_text_time: float = 0.0
var attack_timer: float = 0.0
var windup_timer: float = 0.0
var winding_up: bool = false
var player: Node2D

func _ready() -> void:
    add_to_group("enemies")
    player = get_parent().get_node_or_null("Player") as Node2D
    queue_redraw()

func _physics_process(delta: float) -> void:
    if combat_text_time > 0.0:
        combat_text_time = maxf(0.0, combat_text_time - delta)
    if not alive or not is_instance_valid(player):
        queue_redraw()
        return
    attack_timer = maxf(0.0, attack_timer - delta)
    var distance := global_position.distance_to(player.global_position)
    if winding_up:
        windup_timer -= delta
        if windup_timer <= 0.0:
            winding_up = false
            attack_timer = ATTACK_COOLDOWN
            if distance <= MELEE_RANGE + 10.0 and player.has_method("take_damage"):
                player.take_damage(1)
    elif distance <= MELEE_RANGE and attack_timer <= 0.0:
        winding_up = true
        windup_timer = WINDUP_TIME
    elif distance > MELEE_RANGE and distance <= DETECTION_RANGE:
        var direction := global_position.direction_to(player.global_position)
        global_position += direction * minf(MOVE_SPEED * delta, distance - MELEE_RANGE)
    queue_redraw()

func take_hit() -> void:
    if not alive:
        return
    var result: Dictionary = CombatResolver.resolve()
    var damage: int = result["damage"]
    combat_text = result["result"] if damage == 0 else str(damage) + (" CRIT!" if result["result"] == "CRIT!" else "")
    combat_text_time = 0.7
    health -= damage
    if health <= 0:
        alive = false
        winding_up = false
        remove_from_group("enemies")
        queue_redraw()
        await get_tree().create_timer(2.0).timeout
        if not is_inside_tree():
            return
        health = MAX_HEALTH
        alive = true
        add_to_group("enemies")
    queue_redraw()

func _draw() -> void:
    if alive:
        draw_circle(Vector2.ZERO, 15.0, Color("#b97b4a") if winding_up else Color("#618b51"))
        draw_circle(Vector2(-7, -4), 3.0, Color("#e0c88a"))
        draw_circle(Vector2(7, -4), 3.0, Color("#e0c88a"))
        draw_rect(Rect2(-19, -29, 38, 5), Color("#402b2b"))
        draw_rect(Rect2(-19, -29, 38.0 * health / MAX_HEALTH, 5), Color("#a5c86c"))
        if winding_up:
            draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 24, Color("#f4a35d"), 2.5)
    if combat_text_time > 0.0:
        draw_string(ThemeDB.fallback_font, Vector2(-22, -39), combat_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f4d17d"))
