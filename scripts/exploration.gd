extends Node2D

# Presentation memory is deliberately independent of actor simulation/navigation.
var arena: Node2D
var remembered: Dictionary = {}
var current: Dictionary = {}
var clock := 0.0
const CELL := 16
const VIEW := 440.0

func reset() -> void:
	remembered.clear()
	current.clear()
	# Only Room A's static composition is initially known.
	for x in range(32, 608, CELL):
		for y in range(48, 384, CELL):
			remembered[Vector2i(x, y)] = true
	clock = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	if arena.player == null:
		return
	clock -= delta
	if clock <= 0.0:
		refresh()
		clock = 0.08
	for actor in arena.goblins:
		actor.visible = arena.point_visible(actor.position)
	for container in [arena.loot, arena.projectiles]:
		for item in container.get_children():
			item.visible = arena.point_visible(item.position)
	for item in arena.interactables:
		item.visible = arena.interactable_visible(item)
	for trap in arena.traps:
		trap.visible = arena.point_visible(trap.position)

func refresh() -> void:
	current.clear()
	var origin: Vector2 = arena.player.position
	for x in range(int(floor((origin.x - VIEW) / CELL)) * CELL, int(origin.x + VIEW), CELL):
		for y in range(int(floor((origin.y - VIEW) / CELL)) * CELL, int(origin.y + VIEW), CELL):
			var cell := Vector2i(x, y)
			var center := Vector2(cell) + Vector2(8, 8)
			if origin.distance_to(center) > VIEW:
				continue
			var query := PhysicsRayQueryParameters2D.create(origin, center, 1)
			var hit := get_world_2d().direct_space_state.intersect_ray(query)
			# The front face of an opaque wall/door can be seen; never reveal behind it.
			if hit.is_empty() or center.distance_to(hit.position) < 10.0:
				current[cell] = true
				remembered[cell] = true
	queue_redraw()

func _draw() -> void:
	if arena.player == null:
		return
	# Cover only the camera viewport, including the tall original wall artwork.
	var start: Vector2 = arena.camera.position - Vector2(336, 296)
	for x in range(int(floor(start.x / CELL)) * CELL, int(start.x + 672), CELL):
		for y in range(int(floor(start.y / CELL)) * CELL, int(start.y + 592), CELL):
			var cell := Vector2i(x, y)
			if not current.has(cell):
				draw_rect(Rect2(Vector2(cell), Vector2(CELL, CELL)), Color(0.02, 0.025, 0.03, 0.86) if remembered.has(cell) else Color("080a0d"))
