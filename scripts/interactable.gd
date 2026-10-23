extends StaticBody2D

var arena: Node2D
var is_button := false
var opened := false
var blocker: CollisionShape2D

func _ready() -> void:
	collision_layer = 0 if is_button else 1
	collision_mask = 0
	if not is_button:
		blocker = CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16, 64)
		blocker.shape = shape
		add_child(blocker)
	queue_redraw()

func prompt() -> String:
	return "Reset all goblins" if is_button else ("Close door" if opened else "Open door")

func activate() -> void:
	if is_button:
		arena.request_respawns()
		return
	if opened:
		for actor in [arena.player] + arena.goblins:
			if actor.hp > 0 and Rect2(position - Vector2(16, 40), Vector2(32, 80)).has_point(actor.position):
				arena.log_event("Door occupied - cannot close")
				return
	set_open(not opened)

func set_open(value: bool) -> void:
	opened = value
	collision_layer = 0 if opened else 1
	queue_redraw()

func _draw() -> void:
	if is_button:
		draw_rect(Rect2(-12, -24, 24, 24), Color("24272a"))
		draw_rect(Rect2(-10, -22, 20, 20), Color("736c58"))
		draw_rect(Rect2(-8, -20, 16, 16), Color("343831"))
		draw_rect(Rect2(-5, -18, 10, 10), Color("a38145"))
		draw_rect(Rect2(-4, -18, 8, 2), Color("d0b776"))
		for x in [-9, 8]:
			for y in [-21, -5]:
				draw_rect(Rect2(x, y, 2, 2), Color("b0a68a"))
		return
	# Pixel-aligned worn timber, iron straps, studs and substantial masonry jambs.
	if not opened:
		draw_rect(Rect2(-9, -32, 18, 64), Color("242322"))
		for y in range(-32, 32, 8):
			draw_rect(Rect2(-7, y, 14, 7), Color("594535") if posmod(y, 16) == 0 else Color("67503b"))
			draw_line(Vector2(-5, y + 2), Vector2(3, y + 2), Color("806447"))
		for y in [-23, 21]:
			draw_rect(Rect2(-8, y, 16, 4), Color("333a38"))
			for x in [-6, 4]:
				draw_rect(Rect2(x, y, 2, 2), Color("a18d67"))
		draw_rect(Rect2(-2, -3, 4, 6), Color("b69a5d"))
	else:
		draw_rect(Rect2(-7, -32, 14, 4), Color("806447"))
	for y in [-40, 32]:
		draw_rect(Rect2(-13, y, 26, 8), Color("333832"))
		draw_rect(Rect2(-12, y, 24, 6), Color("777663"))
		draw_line(Vector2(-10, y), Vector2(10, y), Color("99937a"))
