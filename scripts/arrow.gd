extends Node2D

var hazard := false
var damage := 3
var arena: Node2D
var direction := Vector2.RIGHT
var lifetime := 0.0
var finished := false

func _physics_process(delta: float) -> void:
	if arena.escaped or finished:
		return
	var destination := position + direction * 290.0 * delta
	var query := PhysicsRayQueryParameters2D.create(position, destination, 7 if hazard else 5)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hazard and hit.collider in [arena.player] + arena.goblins:
			arena.resolve_hazard(self, hit.collider, "Trap arrow", damage)
		elif hit.collider in arena.goblins and hit.collider.hp > 0:
			arena.resolve_contact(arena.player, hit.collider, "Arrow")
		else:
			report_miss("wall")
		finished = true
		queue_free()
		return
	position = destination
	lifetime += delta
	if lifetime > 3.0:
		report_miss("expired")
		finished = true
		queue_free()
	queue_redraw()

func _draw() -> void:
	var tip := direction * 7.0 + Vector2(0, -13)
	var tail := -direction * 6.0 + Vector2(0, -13)
	draw_line(tail.round(), tip.round(), Color("b9a47a"), 1.0)
	draw_line(tip.round(), (tip - direction.rotated(0.5) * 4).round(), Color("ccd2cf"), 1.0)
	draw_line(tail.round(), (tail + direction.rotated(0.7) * 4).round(), Color("ddd6b3"), 2.0)

func report_miss(reason: String) -> void:
	var message := ("Trap arrow" if hazard else "Arrow") + ": PHYSICAL MISS (" + reason + ")"
	if not hazard or arena.point_visible(position):
		arena.log_event(message)
	else:
		print(message)
