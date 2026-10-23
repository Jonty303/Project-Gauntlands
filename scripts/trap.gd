extends Node2D

var arena: Node2D
var kind := "spike"
@export var warning_time := 0.55
@export var active_time := 0.65
@export var cooldown_time := 2.5
@export var damage := 3
var phase := "armed"
var elapsed := 0.0
var contacts: Array = []

func reset_run() -> void:
	phase = "armed"
	elapsed = 0.0
	contacts.clear()
	queue_redraw()

func overlaps(actor: CharacterBody2D) -> bool:
	var half := Vector2(20, 20) if kind == "spike" else Vector2(24, 12)
	return actor.hp > 0 and actor.position.distance_to(actor.position.clamp(position - half, position + half)) <= actor.feet.shape.radius

func _physics_process(delta: float) -> void:
	if arena.escaped:
		return
	var occupants: Array = ([arena.player] + arena.goblins).filter(overlaps)
	if phase == "armed":
		for actor in occupants:
			if actor.pressure_sensitive:
				phase = "warning"
				elapsed = 0.0
				contacts.clear()
				break
	else:
		elapsed += delta
		if phase == "warning" and elapsed >= warning_time:
			phase = "active"
			elapsed = 0.0
			if kind == "arrow":
				fire()
		elif phase == "active" and elapsed >= active_time:
			if kind == "spike" and contacts.is_empty():
				if arena.point_visible(position):
					arena.log_event("Spikes: PHYSICAL MISS (vacated plate)")
				else:
					print("Spikes: PHYSICAL MISS (vacated plate)")
			phase = "cooldown"
			elapsed = 0.0
		elif phase == "cooldown" and elapsed >= cooldown_time:
			phase = "armed"
			elapsed = 0.0
	if kind == "spike" and phase == "active":
		for actor in occupants:
			if actor not in contacts:
				contacts.append(actor)
				arena.resolve_hazard(self, actor, "Spikes", damage)
	queue_redraw()

func fire() -> void:
	var arrow = preload("res://scripts/arrow.gd").new()
	arrow.arena = arena
	arrow.hazard = true
	arrow.damage = damage
	arrow.direction = Vector2.DOWN
	# Muzzle inside the straight corridor; the plate and victim are independent.
	arrow.position = Vector2(position.x, 272)
	arena.projectiles.add_child(arrow)

func _draw() -> void:
	var half := Vector2(20, 20) if kind == "spike" else Vector2(24, 12)
	draw_rect(Rect2(-half, half * 2), Color("2b302c"))
	draw_rect(Rect2(-half + Vector2(2, 2), half * 2 - Vector2(4, 4)), Color("656457"))
	var warning := Color("cb9147") if phase == "warning" else Color("8c8267")
	draw_rect(Rect2(-half + Vector2(3, 3), half * 2 - Vector2(6, 6)), warning, false, 1)
	for x in [-12, 0, 12]:
		for y in [-8, 8]:
			draw_rect(Rect2(x - 3, y - 2, 6, 4), Color("242928"))
			if kind == "spike" and phase == "active":
				draw_colored_polygon(PackedVector2Array([Vector2(x - 3, y), Vector2(x, y - 15), Vector2(x + 3, y)]), Color("a3aaa2"))
				draw_line(Vector2(x, y - 13), Vector2(x + 1, y - 1), Color("d3d2b7"))
	if kind == "arrow":
		# Brass lane arrows communicate the direction before triggering.
		for y in [-6, 2]:
			draw_polyline(PackedVector2Array([Vector2(-4, y), Vector2(0, y + 4), Vector2(4, y)]), warning)
