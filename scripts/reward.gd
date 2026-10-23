extends Node2D

var arena: Node2D
var kind := "chest"
@export var gold_amount := 20
var opened := false

func prompt() -> String:
	return "Escape dungeon" if kind == "entrance" else ("Empty chest" if opened else "Open chest")

func activate() -> void:
	if arena.simulation_stopped() or arena.player.hp <= 0 or arena.player.position.distance_to(position) >= 48 or not arena.interaction_reachable(self):
		return
	if kind == "entrance":
		arena.escape_run()
	elif not opened:
		opened = true
		arena.gold += maxi(1, gold_amount)
		arena.log_event("Chest: collected %d gold" % maxi(1, gold_amount))
		queue_redraw()

func reset_run() -> void:
	opened = false
	queue_redraw()

func _draw() -> void:
	if kind == "entrance":
		draw_rect(Rect2(-27, -21, 54, 30), Color("090c10"))
		for x in [-32, 24]:
			for y in range(-24, 16, 8):
				draw_rect(Rect2(x, y, 8, 7), Color("777663"))
				draw_rect(Rect2(x, y, 2, 6), Color("99937a"))
		for y in range(-8, 16, 6):
			draw_rect(Rect2(-24, y, 48, 2), Color("777663"))
		draw_polyline(PackedVector2Array([Vector2(-5, -15), Vector2(0, -20), Vector2(5, -15)]), Color("d0b776"), 2)
		return
	# Original pixel-aligned worn timber and iron, matching existing doors.
	draw_rect(Rect2(-17, 1, 34, 8), Color(0.03, 0.03, 0.03, 0.7))
	draw_rect(Rect2(-16, -17, 32, 23), Color("242322"))
	for y in range(-15, 5, 5):
		draw_rect(Rect2(-14, y, 28, 4), Color("67503b"))
		draw_line(Vector2(-10, y + 1), Vector2(9, y + 1), Color("806447"))
	if opened:
		draw_rect(Rect2(-14, -25, 28, 10), Color("594535"))
		draw_rect(Rect2(-13, -15, 26, 9), Color("171b19"))
	else:
		draw_rect(Rect2(-14, -18, 28, 5), Color("9b7a4b"))
	for x in [-11, 8]:
		draw_rect(Rect2(x, -17, 3, 22), Color("333a38"))
		for y in [-14, 1]:
			draw_rect(Rect2(x, y, 2, 2), Color("a18d67"))
	draw_rect(Rect2(-2, -9, 4, 5), Color("b69a5d"))
