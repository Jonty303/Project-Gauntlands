extends Node2D

var arena: Node2D
var direction := Vector2.RIGHT
var lifetime := 0.0
var finished := false

func _physics_process(delta: float) -> void:
	if finished:
		return
	var destination := position + direction * 290.0 * delta
	var query := PhysicsRayQueryParameters2D.create(position, destination, 5)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider in arena.goblins and hit.collider.hp > 0:
			arena.resolve_contact(arena.player, hit.collider, "Arrow")
		else:
			arena.log_event("Arrow: PHYSICAL MISS (wall)")
		finished = true
		queue_free()
		return
	position = destination
	lifetime += delta
	if lifetime > 3.0:
		arena.log_event("Arrow: PHYSICAL MISS (expired)")
		finished = true
		queue_free()
	queue_redraw()

func _draw() -> void:
	var tip := direction * 7.0 + Vector2(0, -13)
	var tail := -direction * 6.0 + Vector2(0, -13)
	draw_line(tail.round(), tip.round(), Color("b9a47a"), 1.0)
	draw_line(tip.round(), (tip - direction.rotated(0.5) * 4).round(), Color("ccd2cf"), 1.0)
	draw_line(tail.round(), (tail + direction.rotated(0.7) * 4).round(), Color("ddd6b3"), 2.0)
