extends Node2D

var arena: Node2D
var kind := "gold"
var quantity := 5
var collected := false

func _physics_process(_delta: float) -> void:
	if collected or arena.player.hp <= 0:
		return
	if position.distance_to(arena.player.position) <= 18 and arena.clear_sight(position, arena.player.position):
		collected = true
		if kind == "gold":
			arena.gold += quantity
		else:
			arena.arrows += quantity
		arena.log_event("Collected %d %s" % [quantity, kind])
		queue_free()

func _draw() -> void:
	draw_ellipse_shadow()
	if kind == "gold":
		for p in [Vector2(-5, 0), Vector2(2, 1), Vector2(-1, -3)]:
			draw_rect(Rect2(p, Vector2(6, 4)), Color("7c562d"))
			draw_rect(Rect2(p, Vector2(5, 2)), Color("d4ad58"))
			draw_rect(Rect2(p, Vector2(2, 1)), Color("f0d58c"))
	else:
		for x in [-4, 0, 4]:
			draw_line(Vector2(x - 3, 5), Vector2(x + 3, -6), Color("b69b67"))
			draw_line(Vector2(x + 1, -4), Vector2(x + 3, -7), Color("cbd1c8"), 2)
			draw_line(Vector2(x - 3, 3), Vector2(x - 4, 6), Color("ddd4b6"), 2)

func draw_ellipse_shadow() -> void:
	draw_rect(Rect2(-8, 2, 16, 4), Color(0.03, 0.03, 0.03, 0.6))
